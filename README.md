# iota-manybody-lua
Libraries to study many-body Hamiltonians with Fermionic and/or Bosonic and/or others particles based on second quantization operators, using the powerful, efficient, lightweight, embeddable scripting Lua language.

# Install
1. Download/Clone repository:
```
git clone https://github.com/rodrigoams/iota-manybody-lua
```

2. Rename `iota-many-body` to `iota`
3. Define the environment variable `IOTA_PATH`
3. Define the Lua modules environment variables

```
export LUA_CPATH=$IOTA_PATH/?.so
export LUA_PATH=$IOTA_PATH/?.lua
```
4. Compile the library

```
cd $IOTA_PATH/fock
make
cd $IOTA_PATH/complex
make
```

5. Read the docs after a succesfull compilation.
