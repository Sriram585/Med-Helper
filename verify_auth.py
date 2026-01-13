import requests
import json

BASE_URL = "http://127.0.0.1:8000"

def test_register_patient():
    print("Testing Patient Registration...")
    payload = {
        "name": "Test Patient",
        "mobile": "1234567890",
        "email": "patient@test.com",
        "username": "test_patient",
        "password": "password123",
        "role": "patient"
    }
    try:
        res = requests.post(f"{BASE_URL}/register", json=payload)
        print(f"Status: {res.status_code}")
        print(f"Response: {res.json()}")
        if res.status_code == 200:
            print("[PASS] Patient Registration Success")
        else:
            print("[FAIL] Patient Registration Failed")
    except Exception as e:
        print(f"[FAIL] Error: {e}")

def test_register_doctor():
    print("\nTesting Doctor Registration...")
    payload = {
        "name": "Test Doctor",
        "mobile": "0987654321",
        "email": "doctor@test.com",
        "username": "test_doctor",
        "password": "password123",
        "role": "doctor",
        "specialty": "Cardiology"
    }
    try:
        res = requests.post(f"{BASE_URL}/register", json=payload)
        print(f"Status: {res.status_code}")
        print(f"Response: {res.json()}")
        if res.status_code == 200:
            print("[PASS] Doctor Registration Success")
        else:
            print("[FAIL] Doctor Registration Failed")
    except Exception as e:
        print(f"[FAIL] Error: {e}")

def test_login_success():
    print("\nTesting Login Success (Patient)...")
    payload = {
        "username": "test_patient",
        "password": "password123",
        "role": "patient"
    }
    try:
        res = requests.post(f"{BASE_URL}/login", json=payload)
        print(f"Status: {res.status_code}")
        print(f"Response: {res.json()}")
        if res.status_code == 200:
            print("[PASS] Login Success")
        else:
            print("[FAIL] Login Failed")
    except Exception as e:
        print(f"[FAIL] Error: {e}")

def test_login_failure():
    print("\nTesting Login Failure (Wrong Password)...")
    payload = {
        "username": "test_patient",
        "password": "wrongpassword",
        "role": "patient"
    }
    try:
        res = requests.post(f"{BASE_URL}/login", json=payload)
        print(f"Status: {res.status_code}")
        print(f"Response: {res.json()}")
        if res.status_code == 401:
            print("[PASS] Login Failed Correctly (401)")
        else:
            print(f"[FAIL] Login Should Fail but got {res.status_code}")
    except Exception as e:
        print(f"[FAIL] Error: {e}")

if __name__ == "__main__":
    test_register_patient()
    test_register_doctor()
    test_login_success()
    test_login_failure()
