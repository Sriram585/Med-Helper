from hashing import Hash

try:
    print("Testing Hash...")
    h = Hash.bcrypt("password123")
    print(f"Hash: {h}")
    v = Hash.verify("password123", h)
    print(f"Verify: {v}")
except Exception as e:
    print(f"Error: {e}")
