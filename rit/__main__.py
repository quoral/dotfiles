"""The entrypoint to all rit commands."""
import os
import glob

import click
import click_completion

from rit import constants, dotfiles, mapping

click_completion.init()


def method_translation(ctx, param, value):
    if value is not None:
        return constants.Method(value)


method_decorator = click.option(
    '--method',
    type=click.Choice(constants.Methods),
    default=constants.DEFAULT_METHOD.value,
    callback=method_translation)


@click.group(name="rit")
def rit():
    """Main entrypoint of rit, the dotfile manager."""
    pass


@rit.command()
@method_decorator
def inject(method):
    """Starts the injection of base dotfiles.

    Injection is used to describe linking and copying."""

    mappings = dotfiles.get_all_mappings(method)

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
        click.secho("No actions to perform.", fg='green')
        raise click.Abort()
    click.confirm(
        "Confirm to inject the following "
        "mappings with method `{}`:\n   {}\n".format(
            method.value, "\n   ".join(
                str(m.mapping) for m in injections_to_perform)),
        abort=True)
    injection_method = mapping.injection_method_picker(method)
    injection_method([ms.mapping for ms in injections_to_perform])


@rit.command(name='list')
@click.option('-v', '--verbose', is_flag=True, default=False)
@method_decorator
def inject_list(verbose, method):
    mappings = dotfiles.get_all_mappings(method)
    if verbose:
        dotfiles.show_mappings_verbose(mappings)
    else:
        dotfiles.show_mappings(mappings)


with dotfiles.acquire_mapping_json() as mapping_json:
    injections = {key: '' for key in mapping_json.keys()}

with dotfiles.acquire_repo() as r:
    git_files = set(
        os.path.join(r.working_dir, f) for f in r.git.ls_files().splitlines())
    path_wildcard = os.path.join(r.working_dir, '**', '*')
    files = {
        os.path.relpath(f, start=r.working_dir): ''
        for f in glob.iglob(path_wildcard)
        if f not in injections and os.path.isfile(f) and f in git_files
    }


@rit.command()
@method_decorator
@click.option('-d', '--destination', required=True)
@click.option(
    '-s',
    '--source',
    required=True,
    type=click_completion.DocumentedChoice(files))
def add(method, destination, source):
    if os.path.isabs(destination):
        raise click.ClickException("Destination seems to be an absolute path. "
                                   "Please quote the options so your shell "
                                   "doesn't auto-expand the parameter.")
    mappings = dotfiles.get_all_mappings(method)
    source_mapped = [m for m in mappings if m.source == source]
    if len(source_mapped) > 0:
        raise click.ClickException(
            'Already mapped source `{}`'.format(source_mapped[0].source))
    expanded_destination = os.path.expanduser(destination)
    expanded_source = os.path.expanduser(source)

    if os.path.exists(expanded_destination):
        raise click.ClickException(
            'Destination {} already exists.'.format(expanded_destination))
    if not os.path.exists(expanded_source):
        raise click.ClickException(
            'Source {} does not exist'.format(expanded_source))

    with dotfiles.acquire_mapping_json(writeable=True) as mapping_json:
        mapping_json[source] = destination


@rit.command()
@click.argument('source', type=click_completion.DocumentedChoice(injections))
def remove(source):
    if source not in injections:
        raise click.ClickException(
            'Injection `{}` does not exist'.format(source))
    with dotfiles.acquire_mapping_json(writeable=True) as mapping_json:
        if source not in mapping_json:
            click.ClickException(
                'Injection `{}` does not exist within json.'.format(source))
        click.secho('Removing injection `{}` ... '.format(source), nl=False)
        del mapping_json[source]
        click.secho('√', fg='green')
