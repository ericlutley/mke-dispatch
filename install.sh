sudo apt-get update
sudo apt-get install postgresql postgresql-contrib postgis

# Elixer install
wget https://packages.erlang-solutions.com/erlang-solutions_1.0_all.deb && sudo dpkg -i erlang-solutions_1.0_all.deb
sudo apt-get update
sudo apt-get install esl-erlang
sudo apt-get install elixir

# Install/update Hex
mix local.hex

# Install Phoenix
mix archive.install https://github.com/phoenixframework/archives/raw/master/phx_new.ez


#nodejs
curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -
sudo apt-get install -y nodejs





# Project setup

mix deps.get
mix ecto.create
mix ecto.setup

# Running
mix phoenix.server
