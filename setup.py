"""Installs the rit dotfile manager."""
from setuptools import setup, find_packages

setup(
    name="rit",
    version="0.1.0",
    packages=find_packages(),
    install_requires=['click==6.7', 'GitPython==2.1.5', 'colorama==0.3.9'],
    entry_points={'console_scripts': [
        'rit = rit.__main__:rit',
    ]})
