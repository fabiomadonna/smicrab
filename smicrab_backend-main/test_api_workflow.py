#!/usr/bin/env python3
"""
Test script to demonstrate the complete API workflow
"""

import requests
import json
import time

# API base URL
BASE_URL = "http://localhost:8000/api/v1"

def test_complete_workflow():
    """Test the complete analysis workflow"""
    
    print("🚀 Testing Complete SMICRAB API Workflow")
    print("=" * 50)
    
    try:
        # Step 1: Create Analysis
        print("1. Creating Analysis...")
        create_response = requests.post(
            f"{BASE_URL}/analysis/create",
            json={"user_id": "test_user"}
        )
        
        if create_response.status_code != 201:
            print(f"   ❌ Failed to create analysis: {create_response.text}")
            return False
            
        create_data = create_response.json()
        analysis_id = create_data["data"]["id"]
        print(f"   ✅ Analysis created: {analysis_id}")
        
        # Step 2: Save Analysis Parameters
        print("\n2. Saving Analysis Parameters...")
        parameters = {
            "analysis_id": analysis_id,
            "model_type": "Model4_UHI",
            "bool_update": True,
            "bool_trend": True,
            "summary_stat": "mean",
            "user_longitude_choice": 11.2,
            "user_latitude_choice": 45.1,
            "user_coeff_choice": 1.0,
            "bool_dynamic": True,
            "endogenous_variable": "LST_h18",
            "covariate_variables": [
                "maximum_air_temperature_adjusted",
                "mean_air_temperature_adjusted",
                "mean_relative_humidity_adjusted",
                "black_sky_albedo_all_mean"
            ],
            "covariate_legs": [0, 0, 0, 0],
            "user_date_choice": "2011-01-01",
            "vec_options": {
                "groups": 1,
                "px_core": 1,
                "px_neighbors": 3,
                "t_frequency": 12,
                "na_rm": True,
                "NAcovs": "pairwise.complete.obs"
            }
        }
        
        params_response = requests.post(
            f"{BASE_URL}/analysis/parameters",
            json=parameters
        )
        
        if params_response.status_code != 200:
            print(f"   ❌ Failed to save parameters: {params_response.text}")
            return False
            
        print(f"   ✅ Parameters saved successfully")
        
        # Step 3: Check Analysis Status
        print("\n3. Checking Analysis Status...")
        status_response = requests.get(f"{BASE_URL}/analysis/{analysis_id}/status")
        
        if status_response.status_code == 200:
            status_data = status_response.json()
            status = status_data["data"]["status"]
            print(f"   📊 Analysis status: {status}")
        else:
            print(f"   ⚠️  Could not get status: {status_response.text}")
        
        # Step 4: Run Analysis
        print("\n4. Running Analysis...")
        run_response = requests.post(
            f"{BASE_URL}/analysis/run",
            json={"analysis_id": analysis_id}
        )
        
        if run_response.status_code != 200:
            print(f"   ❌ Failed to run analysis: {run_response.text}")
            return False
            
        run_data = run_response.json()
        print(f"   ✅ Analysis started: {run_data['data']['message']}")
        
        # Step 5: Monitor Progress
        print("\n5. Monitoring Analysis Progress...")
        print("   ⏱️  Checking status every 30 seconds...")
        
        max_wait_time = 300  # 5 minutes for test
        check_interval = 30
        elapsed_time = 0
        
        while elapsed_time < max_wait_time:
            status_response = requests.get(f"{BASE_URL}/analysis/{analysis_id}/status")
            
            if status_response.status_code == 200:
                status_data = status_response.json()
                status = status_data["data"]["status"]
                current_module = status_data["data"]["current_module"]
                
                print(f"   📊 Status: {status}, Module: {current_module} ({elapsed_time}s elapsed)")
                
                if status == "completed":
                    print(f"   ✅ Analysis completed successfully!")
                    break
                elif status == "error":
                    print(f"   ❌ Analysis failed with error")
                    break
            else:
                print(f"   ⚠️  Could not get status: {status_response.status_code}")
            
            time.sleep(check_interval)
            elapsed_time += check_interval
        
        if elapsed_time >= max_wait_time:
            print(f"   ⏰ Monitoring timeout reached ({max_wait_time}s)")
            print(f"   📊 Analysis may still be running - check Docker logs")
        
        print(f"\n🎉 Workflow test completed!")
        return True
        
    except Exception as e:
        print(f"❌ Test failed: {e}")
        import traceback
        traceback.print_exc()
        return False

def test_error_cases():
    """Test error cases"""
    
    print("\n🧪 Testing Error Cases")
    print("=" * 50)
    
    # Test 1: Run analysis without parameters
    print("1. Testing run without parameters...")
    create_response = requests.post(
        f"{BASE_URL}/analysis/create",
        json={"user_id": "test_user"}
    )
    
    if create_response.status_code == 201:
        analysis_id = create_response.json()["data"]["id"]
        
        run_response = requests.post(
            f"{BASE_URL}/analysis/run",
            json={"analysis_id": analysis_id}
        )
        
        if run_response.status_code == 400:
            print(f"   ✅ Correctly rejected: {run_response.json()['message']}")
        else:
            print(f"   ❌ Should have been rejected: {run_response.status_code}")
    
    # Test 2: Run non-existent analysis
    print("\n2. Testing run non-existent analysis...")
    run_response = requests.post(
        f"{BASE_URL}/analysis/run",
        json={"analysis_id": "non-existent-id"}
    )
    
    if run_response.status_code == 404:
        print(f"   ✅ Correctly rejected: {run_response.json()['message']}")
    else:
        print(f"   ❌ Should have been rejected: {run_response.status_code}")

if __name__ == "__main__":
    print("Select test to run:")
    print("1. Complete workflow test")
    print("2. Error cases test")
    print("3. Both tests")
    
    choice = input("\nEnter choice (1-3): ").strip()
    
    if choice == "1":
        test_complete_workflow()
    elif choice == "2":
        test_error_cases()
    elif choice == "3":
        test_complete_workflow()
        test_error_cases()
    else:
        print("Invalid choice") 