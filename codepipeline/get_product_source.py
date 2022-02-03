'''
Return the value of the product source file for a given template
'''

import json
import argparse

MAP_FILE = 'codepipeline/template-product-map.json'


if __name__ == '__main__':
    PARSER = argparse.ArgumentParser(prog='get_product_source.py', usage='%(prog)s -f [-m]', \
                                    description='Return the SC Product of the file')

    PARSER.add_argument("-f", "--file_name", type=str, required=True, help="File name")
    PARSER.add_argument("-m", "--map_file", type=str, default='codepipeline/template-product-map.json', \
                            help="secrets manager secret")
    ARGS = PARSER.parse_args()
    FILE_NAME = ARGS.file_name
    MAP_FILE = ARGS.map_file
    result = None

    content = open(MAP_FILE, 'r')
    data = json.load(content)
    content.close()

    if FILE_NAME in data:
        result = data[FILE_NAME]

    print(result)

