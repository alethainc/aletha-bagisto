#!/bin/bash

# Configuration
FAMILY_NAME="bagisto"
KEEP_LAST_N=2  # Number of latest revisions to keep

# Get all active task definitions
TASK_DEFS=$(aws ecs list-task-definitions --family-prefix $FAMILY_NAME --status ACTIVE --output text --query 'taskDefinitionArns[*]')

# Convert to array and sort
readarray -t TASK_DEFS_ARRAY <<< "$TASK_DEFS"
TOTAL_REVISIONS=${#TASK_DEFS_ARRAY[@]}

# Calculate how many to remove
TO_REMOVE=$((TOTAL_REVISIONS - KEEP_LAST_N))

if [ $TO_REMOVE -gt 0 ]; then
    echo "Found $TOTAL_REVISIONS revisions, keeping last $KEEP_LAST_N, removing $TO_REMOVE"
    
    # Deregister older revisions
    for ((i=0; i<$TO_REMOVE; i++)); do
        TASK_DEF="${TASK_DEFS_ARRAY[$i]}"
        echo "Deregistering $TASK_DEF"
        aws ecs deregister-task-definition --task-definition $(basename $TASK_DEF)
    done
else
    echo "Only $TOTAL_REVISIONS revisions found. Nothing to clean up."
fi 