"""The entrypoint to all rit commands."""
import click
from rit import constants
from rit import dotfiles


@click.group(name="rit")
def rit():
    """Main entrypoint of rit, the dotfile manager."""
    pass


@rit.command()
@click.option('--method', type=click.Choice(constants.METHODS),
              default=constants.LINK)
@click.option('--dryrun/--no-dryrun', is_flag=True, default=False)
def inject(method, dryrun):
    """Starts the injection of base dotfiles.

    Injection is used to describe linking and copying."""

    mappings = dotfiles.get_all_mappings()
    if dryrun:
        dotfiles.show_mappings(mappings)
        return

    if method == constants.COPY:
        raise click.UsageError("Copy is currently not implemented."
                               "Please use link.")
