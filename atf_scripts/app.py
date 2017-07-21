import glob
import subprocess
import os
from collections import defaultdict

files_opensdl = [file for file in glob.glob('localrepo' + '/**/*', recursive=True)]

files_applink = [file for file in glob.glob('localrepo_applink' + '/**/*', recursive=True)]

#extensions = ['doc', 'dot', 'xls', 'xlt']




def check_names(files):
    users_dict = defaultdict(list)
    for f in files:
        filename = f.split('\\')[-1]
        if 'FORD' not in filename and 'SDLOPEN' not in filename:
            for ext in extensions:
                if ext in filename and os.path.isfile(f):
                    task = ["svn", "log", f]
                    p = subprocess.Popen(task,stdout=subprocess.PIPE, shell=True)
                    (output, err) = p.communicate()
                    try:
                        user = str(output.split(b'------------------------------------------------------------------------')[1].split(b'|')[-3],'utf-8')
                        users_dict[user].append(f)
                    except IndexError:
                        pass
    generate_reports(users_dict)


def check_names_applink(files):
    for f in files:
        filename = f.split('\\')[-1]
        if 'FORD' not in filename and 'APPLINK' not in filename and 'PASA' not in filename:
            #for ext in extensions:
                #if ext in filename and os.path.isfile(f):
            if os.path.isfile(f):
                print(f)
                with open('report_applink.txt', "a") as input_file:
                    print(f, file=input_file)



def generate_reports(findings):
    with open('report.txt', "w") as input_file:
        for k, v in findings.items():
            print(k, file=input_file)
            for v1 in v:
                print("--- "+v1, file=input_file)
            print("\n", file=input_file)

#check_names(files_opensdl)
check_names_applink(files_applink)
