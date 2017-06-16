#!/usr/bin/env python3

#
# Copyright (c) 2017 The Hyve B.V.
# This code is licensed under the GNU Affero General Public License (AGPL),
# version 3, or (at your option) any later version.
#

'''List paths to Maven pom.xml files for all submodules in a project.

This command-line utility parses a pom.xml Maven project definition
file and lists the relative paths to the pom.xml files for all
submodules the project defines.
'''

import sys
import os
import argparse
import xml.etree.ElementTree as ET


def parse_args(argv):
    'Parse the arguments for the script into a namespace.'
    parser = argparse.ArgumentParser(
        description='List paths to Maven pom.xml files for '
                    'all submodules in a project.')
    parser.add_argument('root_pom',
                        help='path to the root POM file of the '
                             'Maven project')
    return parser.parse_args(argv)


def get_submodules(pom_filename):
    'Infer the filenames of submodule POM files from a POM file.'
    project_dir = os.path.dirname(pom_filename)
    # parse the modules section from the XML file
    project = ET.parse(pom_filename).getroot()
    module_list_elem = project.find('modules')
    try:
        # infer the relative path to each POM file listed
        for module_elem in module_list_elem.iter('module'):
            yield os.path.join(project_dir,
                               module_elem.text,
                               'pom.xml')
    except AttributeError as e:
        #  no module section in this POM, end the iterator
        raise StopIteration


def main(argv):
    'Run the script with the specified command line arguments.'
    options = parse_args(argv[1:])
    os.chdir(os.path.dirname(options.root_pom))
    pom_fnames = [os.path.basename(options.root_pom)]
    # TODO: include pom_fnames added later into the iteration
    for filename in pom_fnames:
        pom_fnames.extend(get_submodules(filename))
    for filename in sorted(pom_fnames):
        print(filename)
    

if __name__ == '__main__':
    sys.exit(main(sys.argv))
