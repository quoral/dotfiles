"""The entrypoint to all rit commands."""
import click

from rit import constants, dotfiles, mapping


def method_translation(ctx, param, value):
    if value is not None:
        return constants.Method(value)


@click.group(name="rit")
def rit():
    """Main entrypoint of rit, the dotfile manager."""
    pass


@rit.command()
@click.option(
    '--method',
    type=click.Choice(constants.Methods),
    default=constants.DEFAULT_METHOD.value,
    callback=method_translation)
@click.option('--dryrun/--no-dryrun', is_flag=True, default=False)
def inject(method, dryrun):
    """Starts the injection of base dotfiles.

    Injection is used to describe linking and copying."""

    mappings = dotfiles.get_all_mappings(method)
    if dryrun:
        dotfiles.show_mappings(mappings)
        return

    if method is constants.Method.COPY:
        raise click.UsageError(
            "Copy is currently not implemented. Please use link.")
    dotfiles.detect_injection_conflicts(mappings, method)
