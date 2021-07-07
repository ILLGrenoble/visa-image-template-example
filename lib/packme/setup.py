import glob
import os

from distutils.util import convert_path
from setuptools import find_packages, setup

def find_data(where=".", exclude=None, exclude_directories=None, prefix=""):

    if exclude is None:
        exclude = []

    if exclude_directories is None:
        exclude_directories = []

    out = {}
    stack = [convert_path(where)]
    while stack:
        where = stack.pop(0)
        for name in os.listdir(where):
            fn = os.path.join(where, name)
            d = os.path.join(prefix,os.path.dirname(fn))
            if os.path.isdir(fn):
                stack.append(fn)
            else:
                bad_name = False
                for pattern in exclude:
                    if (fnmatch.fnmatchcase(name, pattern) or fn.lower() == pattern.lower()):
                        bad_name = True
                        break
                if bad_name:
                    continue
                out.setdefault(d, []).append(fn)
            
    out = [(k,v) for k, v in out.items()]
    
    return out

name = "packme"

# Read the package metadata first
pkginfo = {}
exec(open("src/packme/__pkginfo__.py","r").read(),{},pkginfo)

# Set up the sphinx documentation command
cmdclass = {}
command_options = {}
try:
    from sphinx.setup_command import BuildDoc
except ImportError:
    pass
else:
    cmdclass = {'build_sphinx': BuildDoc}
    command_options["build_sphinx"] = {}
    command_options["build_sphinx"]["project"] = ("setup.py",name)  
    command_options["build_sphinx"]["version"] = ("setup.py",pkginfo["__version__"])  
    command_options["build_sphinx"]["source_dir"] = ('setup.py', 'docs')
    
with open("README.md","r") as f:
    pkginfo["__long_description__"] = f.read()

packages = find_packages("src")

data_files = find_data("stubs")

# Copy the scripts
scripts_dir = "scripts"
scripts = glob.glob(os.path.join(scripts_dir,'*'))

setup(name                          = name,
      version                       = pkginfo["__version__"],
      description                   = pkginfo["__description__"],
      long_description              = pkginfo["__long_description__"],
      long_description_content_type = pkginfo["__long_description_content_type__"],
      author                        = pkginfo["__author__"],
      author_email                  = pkginfo["__author_email__"],
      maintainer                    = pkginfo["__maintainer__"],
      maintainer_email              = pkginfo["__maintainer_email__"],
      url                           = pkginfo["__url__"],
      license                       = pkginfo["__license__"],
      classifiers                   = pkginfo["__classifiers__"],
      packages                      = packages,
      package_dir                   = {"" : "src"},
      platforms                     = ['Unix','Windows'],
      install_requires              = ["pyyaml","jinja2"],
      cmdclass                      = cmdclass,
      scripts                       = scripts,
      command_options               = command_options,
      data_files                    = data_files
)
