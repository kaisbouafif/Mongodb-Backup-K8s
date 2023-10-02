	#!/bin/bash
	timestamp=$(date +"%Y%m%d%H%M%S")
	echo "Timestamp: $timestamp"
	# Authenticate using the service account key
    SERVICE_ACCOUNT_KEY="/app/googlekey.json"
    gcloud auth activate-service-account --key-file="$SERVICE_ACCOUNT_KEY"
    # Google Cloud Storage bucket information
    GCS_BUCKET="${{ secrets.GCS_BUCKET }}"
    MONGO_HOST="${{ secrets.MONGO_HOST }}"
    MONGO_PORT=27017
    MONGO_USER="${{ secrets.MONGO_USER }}"
    MONGO_PASSWORD="${{ secrets.MONGO_PASSWORD }}"
    MONGO_AUTH_SOURCE="${{ secrets.MONGO_AUTH_SOURCE }}"  # Specify the authSource
    MONGO_READ_PREFERENCE="primary"  # Specify the readPreference
    MONGO_SSL="false" 
	MONGO_URI="mongodb://${MONGO_USER}:${MONGO_PASSWORD}@${MONGO_HOST}:${MONGO_PORT}/?authSource=${MONGO_AUTH_SOURCE}&readPreference=${MONGO_READ_PREFERENCE}&ssl=${MONGO_SSL}"

    # Attempt to connect to MongoDB
    if ! mongo "${MONGO_URI}" --eval "quit()" 2>/dev/null; then
        echo "Failed to connect to MongoDB"
        exit 1
    fi
	
    # Get a list of all databases
    databases=$(mongo "${MONGO_URI}" --quiet --eval "db.getMongo().getDBs()")
    database_names=$(echo "$databases" | grep -o '"name" : "[^"]*' | awk -F ' : "' '{print $2}')
    IFS=$'\n' read -d '' -a database_name <<< "$database_names"   
    # Loop through the array to print or process the database names
    for db in "${database_name[@]}"; do
        echo "db: $db"
        collections_output=$(mongo "${MONGO_URI}" --quiet  --eval  "db = db.getSiblingDB(db) ; db.getCollectionNames()")
        IFS=$'\n' read -d '' -a COLLECTION_NAMES < <(echo "$collections_output" | jq -r '.[]') 
        for collection in "${COLLECTION_NAMES[@]}"; do
          echo "Collection: $collection"      
          # Use mongoexport to export the collection to a JSON file
          export=$(mongo "${MONGO_URI}" --quiet  --eval "db = db.getSiblingDB(db); JSON.stringify(db.$collection.find().toArray())")
          echo "export done"
          # Export the collection to a JSON file
          export_filename="${collection}.json"
          echo "$export" > "$export_filename"
          # Upload the JSON file to Google Cloud Storage
          gsutil cp *.json $GCS_BUCKET/$db/$timestamp
          rm $export_filename
          echo "Uploaded $collection from $db to Google Cloud Storage"
        done
        echo "Finished exporting collections from database: $db"    
    done
