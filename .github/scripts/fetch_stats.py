import urllib.request
import json
import os

headers = {'User-Agent': 'Mozilla/5.0'}

# Fetch Stars
try:
    req_repo = urllib.request.Request('https://api.github.com/repos/LeanBitLab/LtvLauncher', headers=headers)
    with urllib.request.urlopen(req_repo) as response:
        repo_data = json.loads(response.read().decode())
        stars = repo_data.get('stargazers_count', 0)
except Exception as e:
    print(f'Error fetching stars: {e}')
    stars = 0

# Fetch Releases & Downloads
try:
    req_releases = urllib.request.Request('https://api.github.com/repos/LeanBitLab/LtvLauncher/releases', headers=headers)
    with urllib.request.urlopen(req_releases) as response:
        releases_data = json.loads(response.read().decode())
        version = releases_data[0].get('tag_name', 'unknown') if releases_data else 'unknown'
        downloads = 0
        for release in releases_data:
            for asset in release.get('assets', []):
                downloads += asset.get('download_count', 0)
except Exception as e:
    print(f'Error fetching releases: {e}')
    version = 'unknown'
    downloads = 0

def format_num(n):
    if n >= 1000000:
        return f'{n/1000000:.1f}M'
    if n >= 1000:
        return f'{n/1000:.1f}k'
    return str(n)

stars_str = format_num(stars)
downloads_str = format_num(downloads)

github_output = os.environ.get('GITHUB_OUTPUT')
if github_output:
    with open(github_output, 'a') as f:
        f.write(f'stars={stars_str}\n')
        f.write(f'version={version}\n')
        f.write(f'downloads={downloads_str}\n')
