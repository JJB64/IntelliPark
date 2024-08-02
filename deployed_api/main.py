import uuid
from flask import Flask, request, jsonify, g
from flask_cors import CORS
import firebase_admin
import bcrypt
from firebase_admin import credentials, firestore
from datetime import datetime, timedelta
import jwt

app = Flask(__name__)
CORS(app)  # Enable CORS

# Initialize Firebase Admin SDK
cred = credentials.Certificate('key.json')
firebase_admin.initialize_app(cred)

# Get Firestore client
db = firestore.client()

# JWT Secret Key
app.config['SECRET_KEY'] = 'your_secret_key_here'

############## Helper Functions #####################
def generate_token(user):
    token = jwt.encode({
        'sub': user['email'],
        'iat': datetime.utcnow(),
        'exp': datetime.utcnow() + timedelta(days=1)  # Token expires in 1 day
    }, app.config['SECRET_KEY'], algorithm='HS256')
    return token

def verify_token(token):
    try:
        payload = jwt.decode(token, app.config['SECRET_KEY'], algorithms=['HS256'])
        user_email = payload['sub']
        return user_email
    except jwt.ExpiredSignatureError:
        return None
    except jwt.InvalidTokenError:
        return None

def token_required(f):
    def wrap(*args, **kwargs):
        token = None
        if 'Authorization' in request.headers:
            token = request.headers['Authorization'].split(" ")[1]
        
        if not token:
            return jsonify({'message': 'Token is missing!'}), 401

        try:
            user_email = verify_token(token)
            if not user_email:
                return jsonify({'message': 'Token is invalid or expired!'}), 401
            g.current_user = user_email
        except Exception as e:
            return jsonify({'message': str(e)}), 401
        
        return f(*args, **kwargs)
    
    wrap.__name__ = f.__name__
    return wrap

############## Users Routes #####################
# Create a user
@app.route('/create_user', methods=['POST'])
def create_user():
    try:
        data = request.get_json()
        name = data.get('name')
        email = data.get('email')
        password = data.get('passwordHash')
        phone = data.get('phone')
        gender = data.get('gender', '')  # Handle gender as optional

        if not all([name, email, password, phone]):
            return jsonify({'message': 'Missing fields!'}), 400

        password_hash = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')

        # Create user data dictionary with timestamps
        user_data = {
            'name': name,
            'email': email,
            'passwordHash': password_hash,
            'gender': gender,
            'phone': phone,
            'bio': '',
            'role': '',
            'image': 'assets/images/profile.jpg',  # Default profile image
            'createdAt': datetime.now(),
            'updatedAt': datetime.now()
        }

        # Check if email is already in use
        user_ref = db.collection('Users').document(email)
        user_data_check = user_ref.get()
        if user_data_check.exists:
            return jsonify({'message': 'User already exists!'}), 409
        else:
            # Add user data to Firestore
            user_ref.set(user_data)
            # Get user information without passwordHash, createdAt, updatedAt, profileImage and return it to the client
            user_info = {key: val for key, val in user_data.items() if key not in ['passwordHash', 'createdAt', 'updatedAt', 'profileImage']}
            return jsonify({'message': 'User created successfully!', 'user': user_info}), 200

    except Exception as e:
        app.logger.error(f"Error creating user: {e}")
        return jsonify({'message': 'Internal server error'}), 500


# Update user details
@app.route('/update_user', methods=['PUT'])
@token_required
def update_user():
    try:
        data = request.get_json()
        email = g.current_user  # Use the email from the token

        user_ref = db.collection('Users').document(email)

        if not user_ref.get().exists:
            return jsonify({'message': 'User does not exist!'}), 404

        update_data = {key: value for key, value in data.items() if key != 'email' and value is not None}
        update_data['updatedAt'] = datetime.now()

        user_ref.update(update_data)
        return jsonify({'message': 'User updated successfully!'}), 200

    except Exception as e:
        app.logger.error(f"Error updating user: {e}")
        return jsonify({'message': 'Internal server error'}), 500


# API for login
@app.route('/login', methods=['POST'])
def login():
    try:
        data = request.get_json()
        email = data.get('email')
        password = data.get('passwordHash')

        # Get user data from Firestore
        user_ref = db.collection('Users').document(email)
        user_data = user_ref.get()

        if user_data.exists:
            user_data = user_data.to_dict()
            if bcrypt.checkpw(password.encode('utf-8'), user_data['passwordHash'].encode('utf-8')):
                # Exclude sensitive keys when sending user data back to the client
                user_info = {key: val for key, val in user_data.items() if key not in ['passwordHash', 'createdAt', 'updatedAt', 'profileImage']}
                token = generate_token(user_info)
                return jsonify({'message': 'Login successful!', 'user': user_info, 'token': token}), 200
            else:
                return jsonify({'message': 'Invalid password!'}), 401
        else:
            return jsonify({'message': 'User does not exist!'}), 404

    except Exception as e:
        app.logger.error(f"Error during login: {e}")
        return jsonify({'message': 'Internal server error'}), 500


# Get user details
@app.route('/get_user', methods=['GET'])
@token_required
def get_user():
    try:
        email = g.current_user  # Use the email from the token
        user_ref = db.collection('Users').document(email)
        user_data = user_ref.get()

        if user_data.exists:
            user_data = user_data.to_dict()
            return jsonify(user_data), 200
        else:
            return jsonify({'message': 'User does not exist!'}), 404

    except Exception as e:
        app.logger.error(f"Error getting user: {e}")
        return jsonify({'message': 'Internal server error'}), 500


# Delete user
@app.route('/delete_user', methods=['DELETE'])
@token_required
def delete_user():
    try:
        email = g.current_user  # Use the email from the token
        user_ref = db.collection('Users').document(email)
        user_ref.delete()
        return jsonify({'message': 'User deleted successfully!'}), 200

    except Exception as e:
        app.logger.error(f"Error deleting user: {e}")
        return jsonify({'message': 'Internal server error'}), 500


# Change password
@app.route('/change_password', methods=['PUT'])
@token_required
def change_password():
    try:
        data = request.get_json()
        old_password = data.get('oldPassword')
        new_password = data.get('newPassword')
        email = g.current_user  # Use the email from the token

        user_ref = db.collection('Users').document(email)
        user_data = user_ref.get().to_dict()

        if bcrypt.checkpw(old_password.encode('utf-8'), user_data['passwordHash'].encode('utf-8')):
            new_password_hash = bcrypt.hashpw(new_password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
            user_ref.update({'passwordHash': new_password_hash})
            return jsonify({'message': 'Password changed successfully!'}), 200
        else:
            return jsonify({'message': 'Invalid password!'}), 401

    except Exception as e:
        app.logger.error(f"Error changing password: {e}")
        return jsonify({'message': 'Internal server error'}), 500
    

############## Vehicles Routes #####################

# API for adding a vehicle
@app.route('/add_vehicle', methods=['POST'])
def add_vehicle():
    try:
        data = request.get_json()
        make = data.get('make')
        model = data.get('model')
        vin = data.get('vin')
        color = data.get('color')
        regNo = data.get('regNo')
        user_email =  data.get('owner')
        if not all([make, model, color, regNo, user_email]):
            return jsonify({'message': 'Missing fields!'}), 400

        # Create vehicle data dictionary with timestamps
        vehicle_data = {
            'make': make,
            'model': model,
            'vin': vin,
            'color': color,
            'regNo': regNo,
            'owner': user_email,
            'createdAt': datetime.now(),
            'updatedAt': datetime.now()
        }

        # Check if regNo is already in use
        vehicle_ref = db.collection('Vehicles').document(vin)
        vehicle_data_check = vehicle_ref.get()
        if vehicle_data_check.exists:
            return jsonify({'message': 'A Vehicle with this registration number already exists!'}), 409
        else:
            # Add vehicle data to Firestore
            vehicle_ref.set(vehicle_data)
            # Get vehicle information without createdAt, updatedAt and return it to the client
            vehicle_info = {key: val for key, val in vehicle_data.items() if key not in ['vin', 'createdAt', 'updatedAt']}
            return jsonify({'message': 'Vehicle added successfully!', 'vehicle': vehicle_info}), 200

    except Exception as e:
        app.logger.error(f"Error adding vehicle: {e}")
        return jsonify({'message': 'Internal server error'}), 500


# API for editing a vehicle's color
@app.route('/edit_vehicleDetails', methods=['PUT'])
@token_required
def edit_vehicle():
    try:
        data = request.get_json()
        color = data.get('color')
        vehicle_ref = db.collection('Vehicles').document(data.get('regNo'))

        if not vehicle_ref.get().exists:
            return jsonify({'message': 'Vehicle does not exist!'}), 404

        vehicle_data = vehicle_ref.get().to_dict()
        if vehicle_data['owner'] != g.current_user: # Use the email from the token
            return jsonify({'message': 'You are not authorized to edit this vehicle!'}), 403

        vehicle_ref.update({'color': color, 'updatedAt': datetime.now()})
        return jsonify({'message': 'Vehicle color updated successfully!'}), 200

    except Exception as e:
        app.logger.error(f"Error updating vehicle: {e}")
        return jsonify({'message': 'Internal server error'}), 500
    

# Get user's vehicles
@app.route('/get_user_vehicles', methods=['GET'])
@token_required  
def get_user_vehicles():
    try:
        email = g.current_user  # Use the email from the token
        vehic_ref = db.collection('Vehicles')
        vehic_data = vehic_ref.where('owner', '==', email).stream()

        vehicles = [vehic.to_dict() for vehic in vehic_data]

        return jsonify(vehicles), 200

    except Exception as e:
        app.logger.error(f"Error getting user vehicles: {e}")
        return jsonify({'message': 'Internal server error'}), 500

    

############## Passes Routes #####################
#Creating a pass for a vehicle
@app.route('/create_pass', methods=['POST'])
def create_pass():
    try:
        data = request.get_json()
        passid = str(uuid.uuid4())
        regNo = data.get('regNo')
        make = data.get('make') 
        model = data.get('model')
        owner = data.get('owner')
        role = data.get('role')
        qrCode = data.get('qrCode')  
        institution = data.get('institution')

        if not all([regNo, make, model, owner, role, institution, qrCode]):
            return jsonify({'message': 'Missing fields!'}), 400

        # Create pass data dictionary with timestamps
        pass_data = {
            'passid': passid,
            'owner': owner,
            'regNo': regNo,
            'make': make,  
            'model': model,
            'role': role,
            'institution': institution,
            'status': '0',
            'Creation Date': datetime.now(),
            'Expiry Date': datetime.now() + timedelta(days=30),
            'qrCode': qrCode  
        }

        # Add pass data to Firestore
        pass_ref = db.collection('Passes').document(passid)
        pass_ref.set(pass_data)
        
        # Get pass information without createdAt, updatedAt and return it to the client
        pass_info = {key: val for key, val in pass_data.items() if key not in ['Creation Date', 'Expiry Date']}
        return jsonify({'message': 'Pass created successfully!', 'pass': pass_info}), 200
    except Exception as e:
        app.logger.error(f"Error adding vehicle: {e}")
        return jsonify({'message': 'Internal server error'}), 500



# API to approve the pass for a vehicle. Function will chnage status of pass to approved.
@app.route('/approve_pass', methods=['PUT'])
@token_required
def approve_pass():
    try:
        data = request.get_json()
        status = data.get('status')
        passid = data.get('passid')
        pass_ref = db.collection('Passes').document(passid)

        if not pass_ref.get().exists:
            return jsonify({'message': 'Pass does not exist!'}), 404
        else:
            if status != '1':
                return jsonify({'message': 'Pass already approved!'}), 409
            else:                
                pass_ref.update({'status': '1', 'updatedAt': datetime.now()})
                return jsonify({'message': 'Pass approved successfully!'}), 200
    
    except Exception as e:
        app.logger.error(f"Error updating pass: {e}")
        return jsonify({'message': 'Internal server error'}), 500
    

# API to check a users passes
@app.route('/get_user_passes', methods=['GET'])
@token_required
def get_user_passes():
    try:
        email = g.current_user  # Use the email from the token
        pass_ref = db.collection('Passes')
        pass_data = pass_ref.where('owner', '==', email).stream()

        passes = [pass_.to_dict() for pass_ in pass_data]

        return jsonify(passes), 200

    except Exception as e:
        app.logger.error(f"Error getting user passes: {e}")
        return jsonify({'message': 'Internal server error'}), 500



############## Location Routes #####################
# API for adding a location to database
@app.route('/add_location', methods=['POST'])
def add_location():
    try:
        data = request.get_json()
        location_coordinates = data.get('locationid')
        owner = data.get('owner')
        if not all([location_coordinates, owner]):
            return jsonify({'message': 'Missing fields!'}), 400

        # Create location data dictionary with timestamps
        location_data = {
            'locationid': location_coordinates,
            'owner': owner,
            'createdAt': datetime.now(),
        }

        # Add location data to Firestore
        location_ref = db.collection('Locations').document(location_coordinates)
        location_ref.set(location_data)
        
        # Get location information without createdAt, updatedAt and return it to the client
        location_info = {key: val for key, val in location_data.items() if key not in ['createdAt']}
        return jsonify({'message': 'Location added successfully!', 'location': location_info}), 200
    except Exception as e:
        app.logger.error(f"Error adding location: {e}")
        return jsonify({'message': 'Internal server error'}), 500
    
#Api to retrieve all the users saved locations
@app.route('/get_user_locations', methods=['GET'])
@token_required
def get_user_locations():
    try:
        email = g.current_user  # Use the email from the token
        loc_ref = db.collection('Locations')
        loc_data = loc_ref.where('owner', '==', email).stream()

        locations = [loc.to_dict() for loc in loc_data]

        return jsonify(locations), 200

    except Exception as e:
        app.logger.error(f"Error getting user locations: {e}")
        return jsonify({'message': 'Internal server error'}), 500