import gdown
import os
import sys
from pathlib import Path


def download_cmsaf(data_dir):
    """Download CMSAF LST zip file from Google Drive"""
    try:
        # Google Drive file ID and output path
        CMSAF_LST_ZIP_FILE_ID = "1OU8u2rysNmp_X9aw7P4CVYFJ0l1q2dS_"
        output_path = Path(data_dir) / "LST_CMSAF_2011_2020.zip"

        # Create data directory if it doesn't exist
        os.makedirs(data_dir, exist_ok=True)

        # Download the file
        url = f"https://drive.google.com/uc?id={CMSAF_LST_ZIP_FILE_ID}"
        gdown.download(url, str(output_path), quiet=False)

        # Verify download
        if output_path.exists() and os.path.getsize(output_path) > 0:
            print(f"Download successful: {output_path}")
            return True
        else:
            print("Download failed: File not created or empty")
            return False

    except Exception as e:
        print(f"Download failed: {str(e)}")
        return False


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python cmsaf_sal_download.py <data_directory>")
        sys.exit(1)

    success = download_cmsaf(sys.argv[1])
    sys.exit(0 if success else 1)