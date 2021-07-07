import collections
import glob
import jinja2
import jinja2.meta
import json
import os
import pprint
import sys
import yaml

from typing import Dict, List

class PackerTemplate:
    """This class implements one packer template.
    Basically, a packer template is made of four sections:
    - description: a string that explains the purpose of the template
    - variables: a dictionary of variables used in the template through jinja2 mechanism
    - builders: a list of dictionaries where each dictionary defines the type of image that will be built
    - provisioners: a list of dictionaries where each dictionary defines actions used to configure the image
    - processors: a list of dictionaries where each dictionary defines actions to be run after the image is built
    """

    def __init__(self, name: str, yaml_node: dict, packages: List[str], packages_base_dir: str, templates_base_dir: str) -> None:
        """Constructor
        """

        self._name = name  
        
        self._packages_base_dir = packages_base_dir
        self._templates_base_dir = templates_base_dir

        environment_file = os.path.join(self._templates_base_dir,self._name,"environment.yml")
        self._read_environment_file(environment_file)
        self._environment.update(os.environ)

        # Fetch the 'packer' node
        packer_node = yaml_node.get("packer", {})

        # Fetch the 'description' node from the packer node
        self._description = packer_node.get("description", "No description provided")

        # Fetch the '_variables' node from the packer node
        self._variables = packer_node.get("variables", {})

        # Fetch the 'builders' node from the packer node
        self._builders = packer_node.get("builders", [])
        for builder in self._builders:
            self._update_builder(builder)

        # Fetch the 'provisioners' node from the packer node
        self._provisioners = packer_node.get("provisioners", [])

        # Case of the file based provisioner, update the source path
        for provisioner in self._provisioners:
            self._update_provisioner(provisioner,os.path.join(self._templates_base_dir,self._name))

        # Fetch the 'postprocessors' node from the packer node
        self._postprocessors = packer_node.get("postprocessors", [])

        self._load_packages(packages)

    def _read_environment_file(self, environment_file):
        """Read YAML environemnt file and populate os.environ

        Parameters
        ----------
        environment_file: str
            Path to the environment file.
        """

        if not os.path.exists(environment_file):
            return

        self._environment = {}
        # The vm_name is set as part of the jinja environment
        self._environment["vm_name"] = self._name

        with open(environment_file, "r") as fin:
            env = yaml.safe_load(fin)
            for k,v in env.get("environment",{}).items():
                self._environment[k] = str(v)

    def _update_builder(self, builder: Dict[str,str]):
        """Update some fields of a builder.

        Parameters
        ----------
        builder: dict
            The builder to update.
        """

        builder["output_directory"] = "builds"
        if not os.path.isabs(builder["output_directory"]):
            builder["output_directory"] = os.path.join(self._templates_base_dir,self._name,builder["output_directory"])

        builder["http_directory"] = "http"
        if not os.path.isabs(builder["http_directory"]):
            builder["http_directory"] = os.path.join(self._templates_base_dir,self._name,builder["http_directory"])

        # For convenience set the vm name with a fixed standardized value
        builder["vm_name"] = "{}-{}.iso".format(self._name,builder["type"])

    def _update_provisioner(self, provisioner : Dict[str,str], base_dir : str):
        """Update some fields of a provisioner.

        Parameters
        ----------
        provisioner: dict
            The provisioner to update.

        base_dir: str
            The base directory for this provisioner.
        """

        if not provisioner["type"] in ["file","shell"]:
            return

        for k,v in provisioner.items():
            if k in ["source","script"] and not os.path.isabs(provisioner[k]):
                provisioner[k] = os.path.join(base_dir,provisioner[k])

    @property
    def builders(self) -> list:
        """Returns the list of packer builders of this :class:`PackerTemplate`.
        """

        return self._builders

    @property
    def description(self) -> str:
        """Returns the description of this :class:`PackerTemplate`.
        """

        return self._description

    @property
    def name(self) -> str:
        """Returns the name of this :class:`PackerTemplate`.
        """

        return self._name

    @property
    def postprocessors(self) -> list:
        """Returns the postprocessors of this :class:`PackerTemplate`.
        """

        return self._postprocessors

    @property
    def provisioners(self) -> list:
        """Returns the provisioners of this :class:`PackerTemplate`.
        """

        return self._provisioners

    @property
    def variables(self) -> dict:
        """Returns the variables of this :class:`PackerTemplate`.
        """

        return self._variables

    def set_parent(self, parent_template: "PackerTemplate"):
        """Set the parent template to this :class:`PackerTemplate`.

        This defines a relationship for future packer run in the sense that the child template will start directly from the image of 
        its parent template.

        Parameters
        ----------
        parent_template: :class:`PackerTemplate`
            The :class:`PackerTemplate` of the parent template to connect the child template with.
            
        """

        # List of the builder names for the child template
        child_builder_names = [builder["name"] for builder in self._builders]

        # Loop over the builder of the parent template
        for builder in parent_template.builders:

            builder_name = builder["name"]

            # If this is a builder specific to the parent config, copy it in the child config and set it with an image dependency
            if builder_name not in child_builder_names:
                parent_builder = {}
                parent_builder["name"] = builder_name
                parent_builder["type"] = builder["type"]
                parent_builder["iso_url"] = os.path.join(builder["output_directory"],"{}-{}.iso".format(parent_template.name, builder_name))
                parent_builder["iso_checksum"] = "none"
                parent_builder["headless"] = "{{ headless }}"
                self._builders.insert(0,parent_builder)

            # If the builder is also defined in the child config, use the child config one and specify the image dependency
            else:

                builder = next((b for b in self._builders if b["name"] == builder_name),None)
                if builder is None:
                    continue

                builder["iso_url"] = os.path.join(self._templates_base_dir,parent_template.name,"builds","{}-{}.iso".format(parent_template.name, builder_name))
                builder["iso_checksum"] = "none"
                builder["headless"] = "{{ headless }}"

    def _load_packages(self, packages: List[str]):
        """Load the non-standard package YAML file and append them as provisioners of this :class:`PackerTemplate`.

        Parameters
        ----------
        list
            The non-standard packages to append.    
        """

        # If *" is in the list, fetch all the packages
        if "*" in packages:
            packages_dir = glob.glob(os.path.join(self._packages_base_dir,"*"))
        # Otherwise just fetch the selected ones
        else:
            packages_dir = []
            for package in packages:
                package_dir = os.path.join(self._packages_base_dir,package)
                if os.path.exists(package_dir) and os.path.isdir(package_dir):
                    packages_dir.append(package_dir)

        # Loop over the packages directories
        for package_dir in packages_dir:
            
            # Build the path to the package manifest file (YAML)
            manifest_file = os.path.join(package_dir,"manifest.yml")
            
            # Open and load the provisioners list from the manifest file
            try:
              fin = open(manifest_file, "r")
            # If the manifest does not exist, the provisioners list is set to an empty list
            except FileNotFoundError:
                manifest_data: List = []
            else:
                root_node = yaml.safe_load(fin)
                manifest_data = root_node["provisioners"]

            # Loop over the provisioners list and update when necessary relative paths with absolute one for packer to run correctly
            for provisioner in manifest_data:
                self._update_provisioner(provisioner,os.path.join(package_dir,self._name))

            # Extend the current provisioners list with the ones of the selected packages
            self._provisioners.extend(manifest_data)
            
    def dump(self, output_file: str, **kwargs):
        """Dump this PackerTemplate to a file.

        Parameters
        ----------
        output_file: str
            The path to the output json file for this :class:`PackerTemplate`.
        """

        # Get the basename and the ext of the output_file
        basename, ext = os.path.splitext(output_file)
        # If the ext is different from .json set it to .json
        if ext != ".json":
            ext = ".json"

        # Reformat the output_file
        output_file = "{}{}".format(basename, ext)

        # This will be the node to be dumped
        node = {}
        node["description"] = self._description
        node["variables"] = self._variables
        node["builders"] = self._builders
        node["provisioners"] = self._provisioners
        node["post-processors"] = self._postprocessors

        stringified_node = repr(node)

        # Create a jinja evironment for parsing the manifest
        env = jinja2.Environment()
        # Parse the string with jinja templates in unrendered state in order to get te set of all jinja templates
        ast = env.parse(stringified_node)
        jinja_templates = jinja2.meta.find_undeclared_variables(ast)
        # Retrieve those templates which are not declared in the environment. These are the undefined templates.
        undefined = jinja_templates.difference(self._environment.keys())

        # If there are some undefined templates, stop here.
        if undefined:
            print(f'The following variables are undefined: {undefined!r}')
            sys.exit(1)
        
        template = env.from_string(stringified_node)
        rendered = template.render(**self._environment)

        # Dump to the output file
        with open(output_file, "w") as fout:
            json.dump(yaml.safe_load(rendered), fout, **kwargs)

    def __str__(self) -> str:
        """Returns the string representation for this :class:`PackerTemplate`.
        """

        d : collections.OrderedDict = collections.OrderedDict()
        d["description"] = self._description
        d["variables"] = self._variables
        d["builders"] = self._builders
        d["provisioners"] = self._provisioners
        d["post-processors"] = self._postprocessors

        return pprint.pformat(d)
