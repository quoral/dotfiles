for f in ~/src/dotfiles/*
do
    ln -s "$f" "$HOME/.${f##*/}"
done
