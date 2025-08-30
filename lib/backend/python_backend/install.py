#!/usr/bin/env python
"""
Installation helper script for Mangrove Watch AI Backend
Checks Python version and installs required dependencies
"""

import sys
import subprocess
import os
from pathlib import Path

def check_python_version():
    """Check if Python version is 3.13 or higher"""
    version = sys.version_info
    print(f"Python version: {version.major}.{version.minor}.{version.micro}")
    
    if version.major < 3 or (version.major == 3 and version.minor < 13):
        print("❌ Error: Python 3.13 or higher is required")
        print("Please upgrade your Python installation")
        return False
    
    print("✅ Python version is compatible")
    return True

def create_virtual_env():
    """Create virtual environment if it doesn't exist"""
    venv_path = Path("venv")
    
    if venv_path.exists():
        print("✅ Virtual environment already exists")
        return True
    
    print("Creating virtual environment...")
    try:
        subprocess.run([sys.executable, "-m", "venv", "venv"], check=True)
        print("✅ Virtual environment created")
        return True
    except subprocess.CalledProcessError as e:
        print(f"❌ Failed to create virtual environment: {e}")
        return False

def get_pip_command():
    """Get the correct pip command for the current environment"""
    if os.name == 'nt':  # Windows
        venv_pip = Path("venv/Scripts/pip.exe")
    else:  # Unix/Linux/Mac
        venv_pip = Path("venv/bin/pip")
    
    if venv_pip.exists():
        return str(venv_pip)
    return sys.executable + " -m pip"

def upgrade_pip():
    """Upgrade pip to latest version"""
    print("Upgrading pip...")
    pip_cmd = get_pip_command()
    
    try:
        subprocess.run(f"{pip_cmd} install --upgrade pip".split(), check=True)
        print("✅ Pip upgraded successfully")
        return True
    except subprocess.CalledProcessError as e:
        print(f"⚠️  Warning: Failed to upgrade pip: {e}")
        return True  # Continue anyway

def install_requirements():
    """Install requirements from requirements.txt"""
    print("\nInstalling requirements...")
    pip_cmd = get_pip_command()
    
    # First, install core packages that others depend on
    core_packages = [
        "wheel",
        "setuptools",
        "pip",
    ]
    
    for package in core_packages:
        try:
            subprocess.run(f"{pip_cmd} install {package}".split(), check=True)
        except:
            pass  # Continue if already installed
    
    # Install main requirements
    try:
        subprocess.run(f"{pip_cmd} install -r requirements.txt".split(), check=True)
        print("✅ All requirements installed successfully")
        return True
    except subprocess.CalledProcessError as e:
        print(f"❌ Failed to install some requirements: {e}")
        print("\nTrying to install packages one by one...")
        return install_requirements_individually()

def install_requirements_individually():
    """Install requirements one by one to identify problematic packages"""
    pip_cmd = get_pip_command()
    failed_packages = []
    successful_packages = []
    
    with open("requirements.txt", "r") as f:
        lines = f.readlines()
    
    total_packages = 0
    for line in lines:
        line = line.strip()
        if line and not line.startswith("#"):
            package = line.split("#")[0].strip()  # Remove inline comments
            if package:
                total_packages += 1
                try:
                    print(f"Installing {package}...")
                    result = subprocess.run(
                        f"{pip_cmd} install {package}".split(), 
                        check=True,
                        capture_output=True,
                        text=True
                    )
                    successful_packages.append(package)
                    print(f"  ✅ {package} installed")
                except subprocess.CalledProcessError as e:
                    print(f"  ⚠️  Failed to install: {package}")
                    # Try to understand why it failed
                    if "No matching distribution" in str(e.stderr):
                        print(f"      Package not found or incompatible with Python {sys.version_info.major}.{sys.version_info.minor}")
                    failed_packages.append(package)
    
    # Print summary
    print(f"\n📊 Installation Summary:")
    print(f"   Total packages: {total_packages}")
    print(f"   ✅ Successfully installed: {len(successful_packages)}")
    print(f"   ⚠️  Failed: {len(failed_packages)}")
    
    if failed_packages:
        print("\n⚠️  The following packages failed to install:")
        for pkg in failed_packages:
            print(f"  - {pkg}")
        
        # Check for specific packages
        critical_failures = []
        optional_failures = []
        
        for pkg in failed_packages:
            if any(x in pkg.lower() for x in ['pymongo', 'motor', 'fastapi', 'uvicorn', 'pydantic']):
                critical_failures.append(pkg)
            else:
                optional_failures.append(pkg)
        
        if critical_failures:
            print("\n❌ Critical packages failed to install:")
            for pkg in critical_failures:
                print(f"   - {pkg}")
            print("\n   These are required for the backend to function.")
            print("   Try installing them manually:")
            for pkg in critical_failures:
                print(f"   pip install {pkg}")
        
        if optional_failures:
            print("\n⚠️  Optional packages failed (backend should still work):")
            for pkg in optional_failures:
                print(f"   - {pkg}")
        
        # Check if TensorFlow is in failed packages
        if any("tensorflow" in pkg.lower() for pkg in failed_packages):
            print("\n💡 TensorFlow installation failed (common with Python 3.13)")
            print("   The backend will work without it using fallback models.")
    
    # Return True if critical packages were installed
    critical_packages = ['fastapi', 'uvicorn', 'motor', 'pymongo', 'pydantic']
    critical_installed = all(
        any(crit in pkg.lower() for pkg in successful_packages) 
        for crit in critical_packages
    )
    
    return critical_installed

def check_mongodb():
    """Check if MongoDB is accessible"""
    print("\nChecking MongoDB connection...")
    try:
        import pymongo
        client = pymongo.MongoClient("mongodb://localhost:27017/", serverSelectionTimeoutMS=5000)
        client.server_info()
        print("✅ MongoDB is running and accessible")
        return True
    except Exception as e:
        print("⚠️  MongoDB is not accessible on localhost:27017")
        print("   Make sure MongoDB is installed and running, or")
        print("   configure MONGODB_URL in your .env file for remote connection")
        return False

def create_env_file():
    """Create .env file if it doesn't exist"""
    env_file = Path("../.env")
    env_example = Path("../.env.example")
    
    if env_file.exists():
        print("✅ .env file already exists")
        return True
    
    if env_example.exists():
        print("Creating .env file from .env.example...")
        try:
            import shutil
            shutil.copy(env_example, env_file)
            print("✅ .env file created. Please edit it with your credentials.")
            return True
        except Exception as e:
            print(f"❌ Failed to create .env file: {e}")
            return False
    else:
        print("⚠️  No .env or .env.example file found")
        print("   Please create a .env file with required credentials")
        return False

def main():
    """Main installation process"""
    print("=" * 60)
    print("Mangrove Watch AI Backend - Installation Script")
    print("=" * 60)
    
    # Check Python version
    if not check_python_version():
        sys.exit(1)
    
    # Create virtual environment
    if not create_virtual_env():
        print("\n⚠️  Continuing without virtual environment...")
    
    # Upgrade pip
    upgrade_pip()
    
    # Install requirements
    if not install_requirements():
        print("\n⚠️  Some packages failed to install, but the backend may still work")
    
    # Check MongoDB
    check_mongodb()
    
    # Create .env file
    create_env_file()
    
    print("\n" + "=" * 60)
    print("Installation Complete!")
    print("=" * 60)
    print("\nNext steps:")
    print("1. Edit ../.env file with your API credentials")
    print("2. Ensure MongoDB is running")
    print("3. Run the backend with: python main.py")
    print("\nFor more information, see README.md")

if __name__ == "__main__":
    main()
