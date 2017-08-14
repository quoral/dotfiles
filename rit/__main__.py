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
    status_mappings = dotfiles.generate_injection_statuses(mappings)
    injection_statuses_not_ok = [
        ms for ms in status_mappings
        if not mapping.okay_status(ms.injection_status)
    ]
    if injection_statuses_not_ok:
        raise click.ClickException("\n" + "\n".join(
            "{}: {}".format(status.name, ", ".join(str(m) for m in mappings))
            for status, mappings in dotfiles.status_mappings(
                injection_statuses_not_ok).items()))
    injections_to_perform = [
        ms for ms in status_mappings
        if ms.injection_status is mapping.InjectionStatus.CanInject
    ]
    if not injections_to_perform:
        click.secho("No action to perform.", color='green')
    click.confirm(
        "Confirm to inject the following "
        "mappings with method `{}`:\n   {}\n".format(
            method.value, "\n   ".join(
                str(m.mapping) for m in injections_to_perform)),
        abort=True)
