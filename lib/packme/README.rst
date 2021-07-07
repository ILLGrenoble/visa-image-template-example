packme
======

overview
~~~~~~~~

``packme`` is a python3 application for generating and running ``packer`` templates.

It works by generating *manifest.json* files out of *manifest.yml* files which contain the packer settings for the image to build. The *manifest.yml* files will be searched in a directory which contains as subdirectories the images to be built using ``packer``. That directory has to be defined from the CLI (``-t/--templates-dir`` option) and has the following structure:

.. code:: shell

     my_templates_directory/
         image1/
             manifest.yml
         ...
         imageN/
             manifest.yml
 
Each manifest.yml has the following structure:

.. code:: shell

     ---
     parameters:
         param1: value1
         ...
         paramN: valueN

     packer:
         description: packer description string
         variables: packer variables dict
         builders: packer builders list
         provisioners: packer provisioners list
         post-processors: packer post processors list

The packer section is strictly the YAML representation of a packer json file with the standards description, variables, builders, provisioners and post-processors packer fields. Those fields can contain Jinja2 templates which can be of two flavors: ``parameters`` or ``environment``. ``parameters`` will be defined in the ``parameters`` section of the YAML file while ``environment`` will be either environment variables or variables passed through the ``packme`` CLI.

In order to run ``packme``, an input configuration file has to be provided. This file is a YAML file which declares the list of the images for which *manifest.json* file will be built and run after with packer. It has the following structure:

.. code:: shell

     ---
     templates:
         image1:
             packages: [package1, ..., packageN]
         ...
         imageN:
             extends: image1

where ``packages`` defines non standard packages that will added as extra provisioners when generating the *manifest.json* file for the corresponding image.

An image can extend another one by starting its building from another image. This is the aim of ``extends`` keyword which allows to declare that dependency.

Documentation
~~~~~~~~~~~~~

`packme documentation <https://packme.readthedocs.io/en/latest/>`__

Prerequesites
~~~~~~~~~~~~~

- packer
- QEMU

Installation
~~~~~~~~~~~~

.. code:: shell

     pip install packme

