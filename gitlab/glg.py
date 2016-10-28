#!/usr/bin/env python

import argparse
import gitlab
import os, os.path

from subprocess import check_call, CalledProcessError

parser = argparse.ArgumentParser(description='Fetch git projects.')
parser.add_argument('name', metavar='NAME', type=str, help='Project partial name')
parser.add_argument('--host', type=str, help='Gitlab host')
parser.add_argument('--token', type=str, help='User token')

args = parser.parse_args()

def create_config_file(host, token):
  home = os.path.expanduser('~')
  with open(os.path.join(home, '.python-gitlab.cfg'), 'w+') as file:
    file.write(
"""[global]
default = gitlab
ssl_verify = true
timeout = 5

[gitlab]
url = """ + host + """
private_token = """ + token)

def fetch_repositories():
  gl = gitlab.Gitlab.from_config('gitlab', [os.path.expanduser('~') + '/.python-gitlab.cfg'])
  gl.auth()

  projects = gl.projects.search(args.name)

  if projects:
    repos = len(projects)
    errors = 0

    for project in projects:
      print("Fetching %s..." % project.name)
      try:
        check_call(['git', 'clone', project.ssh_url_to_repo])
      except CalledProcessError:
        errors += 1

    print("%d project(s) downloaded out of %d" % (repos - errors, repos))

if __name__ == '__main__':
  if args.host and args.token:
    create_config_file(args.host, args.token)

  fetch_repositories()
