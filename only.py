import json

def keep_only_medication():
    input_filename = 'medical_data.json'  # Your current big file
    output_filename = 'medication.json' # The new clean file

    try:
        # 1. Load the original data
        with open(input_filename, 'r') as f:
            data = json.load(f)
        
        print(f"Loaded {len(data)} diseases from {input_filename}...")

        # 2. Create new dictionary with ONLY medication
        cleaned_data = {}
        
        for disease, details in data.items():
            # We specifically extract ONLY the 'medication' key
            # We use .get() to avoid crashing if a disease is missing meds
            meds = details.get('medication', [])
            
            # Construct the new object
            cleaned_data[disease] = {
                "medication": meds
            }

        # 3. Save to a new file
        with open(output_filename, 'w') as f:
            json.dump(cleaned_data, f, indent=4)

        print(f"Success! Cleaned data saved to '{output_filename}'")
        print("Example entry:")
        # Print the first item to show the user the new format
        first_key = list(cleaned_data.keys())[0]
        print(json.dumps({first_key: cleaned_data[first_key]}, indent=4))

    except FileNotFoundError:
        print(f"Error: Could not find '{input_filename}'. Make sure the file exists.")
    except Exception as e:
        print(f"An error occurred: {str(e)}")

if __name__ == "__main__":
    keep_only_medication()