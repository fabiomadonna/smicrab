# Project Setup and Execution Guide

## Prerequisites
Ensure you have the following installed on your system before proceeding:

### 1. Install WSL (For Windows Users)
If you are using Windows, you need to install and enable Windows Subsystem for Linux (WSL):

1. Open PowerShell as Administrator and run:
   ```sh
   wsl --install
   ```
2. Restart your system when prompted.
3. Open WSL and set up a Linux distribution (Ubuntu is recommended).
4. Once inside WSL, update the package manager:
   ```sh
   sudo apt update && sudo apt upgrade -y
   ```

### 2. Install Python and Pip

#### Windows (Using WSL) & Linux:
```sh
sudo apt update && sudo apt install -y python3 python3-pip
```

### 3. Set Up a Virtual Environment
It is recommended to use a virtual environment to manage dependencies.

#### Create a Virtual Environment:
```sh
python3 -m venv venv
```

#### Activate the Virtual Environment:
- **Linux/WSL:**
  ```sh
  source venv/bin/activate
  ```
- **Windows (WSL):**
  ```sh
  source venv/bin/activate
  ```

### 4. Install Required Python Packages
Once the virtual environment is activated, install dependencies:
```sh
pip install -r requirements.txt
```

### 5. Install Required System Utilities (Linux/WSL)
Some datasets require `wget` for downloading and `unzip` for extraction:
```sh
sudo apt install -y wget unzip
```

---

### Configure Environment Variables

1. **Copy `.env.example` to `.env`:**
   - Navigate to the project root directory in your terminal.
   ```sh
   cp .env.example .env
   ```
   - Alternatively, you can manually copy and paste the `.env.example` file in your file explorer and rename the copy to `.env`.
   
2. **Edit `.env`:** Open the `.env` file and replace placeholder values (e.g., `EUMETSAT_USERNAME`, `EUMETSAT_PASSWORD`) with your actual usernames and API keys.
3. **Save `.env`:** Ensure you save the modified `.env` file.

---

## Running the Project

The project is structured into several directories, each corresponding to a specific variable:

- `accumulated_precipitation`
- `air_temperature`
- `Albedo`
- `Land_Surface_Temperature`
- `relative_humidity`
- `sea_level_pressure`
- `solar_irradiance`
- `wind_speed`

Each directory contains a script (`run_<variable_name>.sh`) for processing the respective variable.

### Running Individual Variables
To execute a specific variable automation script, navigate to the respective directory and run:
```sh
bash run_<variable_name>.sh
```
For example, to run the `air_temperature` script:
```sh
cd air_temperature
bash run_air_temperature.sh
```

### Running All Variables
To execute all automation scripts sequentially, run the following script from the project root:
```sh
bash run_all.sh
```
This script will iterate through all directories and execute their respective automation scripts.

---

## Notes
- Ensure all dependencies are installed and environment variables are configured before running the scripts.
- If running on Windows (WSL), use the Linux instructions within the WSL environment.
- The dataset download step might take some time depending on the internet speed.

---

## Troubleshooting
- **Permission Issues:** If you encounter permission errors while running `.sh` scripts, ensure they have execution permissions:
  ```sh
  find . -type f -name "*.sh" -exec chmod +x {} \;
  ```
- **Missing Dependencies:** If any required package is missing, manually install it using:
  ```sh
  pip install <package_name>
  ```
- **Environment Variables Not Loaded:** If the scripts are not recognizing your username or API key, double-check that:
    - You have correctly created the `.env` file from `.env.example`.
    - You have entered the correct values in the `.env` file and saved it.
    - Your scripts are designed to load environment variables from the `.env` file (usually using libraries like `python-dotenv` in Python). If you are using Python, ensure `load_dotenv()` is called at the beginning of your scripts to load the variables from `.env`.
```