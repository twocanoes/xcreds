#!/usr/bin/env python3

# Copyright 2021-2024 Elliot Jordan
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""Given a path to a folder containing profile manifests, this script aims to produce
equivalent Jamf JSON schema manifests."""


__author__ = "Elliot Jordan"
__version__ = "1.1.0"

import argparse
import json
import os
import plistlib
import shutil
import sys
import xml


def build_argument_parser():
    """Build and return the argument parser."""
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument("--version", action="version", version=__version__)
    parser.add_argument(
        "input_dir",
        action="store",
        help="path to a directory containing profile manifests to be converted",
    )
    parser.add_argument(
        "-o",
        "--output-dir",
        default=os.path.dirname(__file__) + "/manifests",
        action="store",
        help="path to output directory of converted Jamf JSON schema manifest files",
    )
    parser.add_argument(
        "-v",
        "--verbose",
        action="count",
        default=0,
        help="output verbosity level (may be specified multiple times)",
    )
    parser.add_argument(
        "--overwrite",
        action="store_true",
        help="overwrite output_dir if it already exists",
    )
    parser.add_argument(
        "--exclude",
        action="append",
        help="manifest domains to skip during conversion (may be "
        "specified multiple times)",
    )
    parser.add_argument(
        "--property-order-increment",
        action="store",
        default="5",
        help="if set to a positive integer, the order of properties will be preserved during "
        "conversion and the property_order value will be incremented by this number. If set to "
        "0, the property_order key will be omitted from the resulting manifest files",
    )

    return parser


def validate_args(args):
    """Do sanity checking and validation on provided input arguments."""

    if not os.path.isdir(os.path.expanduser(args.input_dir)):
        sys.exit("Input path provided is not a directory: %s" % args.input_dir)
    if os.path.exists(os.path.expanduser(args.output_dir)):
        if args.overwrite:
            print("WARNING: Will overwrite output dir: %s" % args.output_dir)
        else:
            sys.exit(
                "Output path already exists: %s\nUse --overwrite to replace contents "
                "of output path with converted files." % args.output_dir
            )
    try:
        int(args.property_order_increment)
    except TypeError:
        sys.exit("Property order increment must be a positive integer or 0.")

    return args


def read_manifest_plist(path):
    """Given a path to a profile manifest plist, return the contents of
    the plist."""
    with open(path, "rb") as openfile:
        try:
            return plistlib.load(openfile)
        except xml.parsers.expat.ExpatError:
            print("Error reading %s" % path)


def process_subkeys(subkeys):
    """Given a list of subkeys, return equivalent JSON schema manifest properties."""

    # Skip keys that describe the payload instead of the setting
    meta_keys = (
        "PayloadDescription",
        "PayloadDisplayName",
        "PayloadIdentifier",
        "PayloadType",
        "PayloadUUID",
        "PayloadVersion",
        "PayloadOrganization",
    )

    # Replacements for plist types with equivalent JSON schema types
    replacements = (
        ("dictionary", "object"),
        ("real", "number"),
        ("float", "number"),
        # Omitting "date" since this is handled by json.dumps(default=str) later
    )

    properties = {}
    for idx, subkey in enumerate(subkeys):
        # Get subkey name
        name = ""
        try:
            if subkey.get("pfm_name", "") != "":
                name = subkey["pfm_name"]
        except AttributeError:
            print("WARNING: Syntax error. Skipping.")
            return

        # Skip specific names
        if name in meta_keys:
            continue
        if name.lower().startswith("pfc_"):
            continue
        if name.lower().startswith("pfmx_"):
            continue

        # Skip specific types
        ignored_types = ("data",)
        if subkey.get("pfm_type") in ignored_types:
            continue

        # Type is the only required property
        # TODO: Is failing back to dictionary too broad an assumption?
        properties[name] = {"type": subkey.get("pfm_type", "object")}

        # Replace with JSON schema types
        for repl in replacements:
            if properties[name]["type"] == repl[0]:
                properties[name]["type"] = repl[1]

        # If type is array, create a dict to store its items
        if properties[name]["type"] == "array":
            properties[name]["items"] = {}

        # Get subkey title, description, and other attributes
        if subkey.get("pfm_title") not in (None, ""):
            properties[name]["title"] = subkey["pfm_title"]
        if subkey.get("pfm_default") not in (None, ""):
            properties[name]["default"] = subkey["pfm_default"]
        if subkey.get("pfm_description") not in (None, ""):
            properties[name]["description"] = subkey["pfm_description"]
        if subkey.get("pfm_format") not in (None, ""):
            properties[name]["pattern"] = subkey["pfm_format"]
        if subkey.get("pfm_documentation_url") not in (None, ""):
            properties[name]["links"] = [
                {"rel": "More information", "href": subkey["pfm_documentation_url"]}
            ]
        if subkey.get("pfm_value_placeholder") not in (None, ""):
            # TODO: Support placeholders.
            pass

        # Convert pre-defined lists of values
        if "pfm_range_list" in subkey:
            properties[name]["enum"] = subkey["pfm_range_list"]
            if "pfm_range_list_titles" in subkey:
                properties[name]["options"] = {
                    "enum_titles": subkey["pfm_range_list_titles"]
                }

        # Recurse into sub-sub-keys
        if "pfm_subkeys" in subkey and not isinstance(subkey["pfm_subkeys"], list):
            print("WARNING: Not a list: %s" % subkey["pfm_subkeys"])
        if isinstance(subkey.get("pfm_subkeys"), list):
            subprop = process_subkeys(subkey["pfm_subkeys"])
            if "items" in properties[name]:
                # If the parent type was array, we're only expecting a single dict
                # here, since an array should only contain a single object type.
                # TODO: Validate this assumption. Some warnings seen in the wild.
                subprop_keys = list(subprop.keys())
                if len(subprop_keys) > 1:
                    print(
                        "WARNING: Array type should only have one subproperty "
                        "key. Skipping all but the first: %s" % subprop_keys
                    )
                elif len(subprop_keys) == 0:
                    print("WARNING: No subproperty keys found in %s key." % name)
                    continue
                array_props = subprop[subprop_keys[0]]
                properties[name]["items"] = array_props
            else:
                properties[name]["properties"] = subprop

    return properties


def convert_to_jamf_manifest(data, property_order_increment=5):
    """Convert a profile manifest plist object to a Jamf JSON schema manifest.

    Reference: https://docs.jamf.com/technical-papers/jamf-pro/json-schema/10.19.0/Understanding_the_Structure_of_a_JSON_Schema_Manifest.html
    """

    # Create schema object
    try:
        schema = {
            "title": "{} ({})".format(data["pfm_title"], data["pfm_domain"]),
            "description": data["pfm_description"],
            "properties": process_subkeys(data["pfm_subkeys"]),
        }
    except KeyError:
        print("ERROR: Manifest is missing a title, domain, or description.")
        return

    # Lock property order
    if property_order_increment > 0:
        order = property_order_increment
        for property in schema["properties"]:
            schema["properties"][property]["property_order"] = order
            order += property_order_increment

    return schema


def write_to_file(path, data):
    """Given a path to a file and JSON data, write the file."""
    path_head, path_tail = os.path.split(path)

    # Create output subfolder if it doesn't exist
    if not os.path.isdir(path_head):
        os.makedirs(path_head)

    # Write file
    with open(os.path.join(path_head, path_tail), "w", encoding="utf-8") as openfile:
        openfile.write(
            json.dumps(
                data,
                ensure_ascii=False,
                indent=4,
                sort_keys=False,
                default=str,
            )
        )


def update_readme(count):
    """Updates README.md file with latest manifest count."""

    with open("README.md", encoding="utf-8") as f:
        readme = f.readlines()
    for idx, line in enumerate(readme):
        if line.startswith("![Manifest Count]("):
            readme[idx] = (
                "![Manifest Count](https://img.shields.io/badge/manifests-%d-blue)\n"
                % count
            )
            break
    with open("README.md", "w", encoding="utf-8") as f:
        f.write("".join(readme))
    print("Updated README.md")


def main():
    """Main process."""

    # Parse command line arguments.
    argparser = build_argument_parser()
    args = validate_args(argparser.parse_args())

    # Expand to full paths
    input_dir = os.path.expanduser(args.input_dir)
    output_dir = os.path.expanduser(args.output_dir)

    # Optionally delete and recreate output path
    if args.overwrite:
        shutil.rmtree(output_dir)
    if not os.path.isdir(output_dir):
        os.makedirs(output_dir)

    # Iterate through manifests in the input path
    count = {"done": 0, "skipped": 0}
    for root, dirs, files in os.walk(input_dir):
        for name in files:
            if name.endswith(".plist"):
                relpath = os.path.relpath(os.path.join(root, name), start=input_dir)

                # Output filename if in verbose mode
                if args.verbose > 0:
                    print("Processing %s" % relpath)

                # Load manifest
                pfm_data = read_manifest_plist(os.path.join(root, name))
                if not pfm_data:
                    count["skipped"] += 1
                    continue

                # Convert to Jamf manifest
                manifest = convert_to_jamf_manifest(
                    pfm_data, int(args.property_order_increment)
                )
                if not manifest:
                    count["skipped"] += 1
                    continue

                # Write manifest file
                output_path = os.path.join(
                    output_dir, relpath.replace(".plist", ".json")
                )
                write_to_file(output_path, manifest)
                count["done"] += 1

    print("Converted %d files. Skipped %d files." % (count["done"], count["skipped"]))
    update_readme(count["done"])


if __name__ == "__main__":
    main()
