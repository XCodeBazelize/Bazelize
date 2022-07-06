import requests
import sys

if __name__ == "__main__":
    print(sys.argv)
    if (len(sys.argv) < 4):
        print("please input with user/repo rule_name output_file_path")
        exit(1)
    
    repo = sys.argv[1]
    name = sys.argv[2]
    path = sys.argv[3]

    headers = {
        'Accept': 'application/vnd.github+json'
    }
    r = requests.get('https://api.github.com/repos/{0}/releases'.format(repo), headers = headers)

    if r.status_code != 200:
        r.raise_for_status()
        exit(1)


    with open(path, 'w') as file:
        print(
'''
extension Repo {{
    /// https://github.com/{1}
    enum {0}: String {{'''.format(name, repo), file=file, end='')

        for release in r.json():
            tag = release["tag_name"]
            _tag_name = tag.replace(".", "_").replace("-", "_")
            tag_name = 'v{0}'.format(_tag_name) if _tag_name[:1].isdigit() else _tag_name
            print(
'''
        case {0} = "{1}"'''.format(tag_name, tag), file=file, end='')

        print(
'''
        var sha256: String {
            return ""
        }
    }
}''', file=file, end='')
