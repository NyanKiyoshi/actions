# `NyanKiyoshi/actions`

A collection of custom GitHub actions.

## Actions

### [`install-zizmor`]

Downloads and installs a given Zizmor version into `PATH`.

Basic usage: installs the default version from [`install-zizmor`]:

```yaml
- name: Install Zizmor
  id: zizmor
  uses: NyanKiyoshi/actions/install-zizmor@v1.x.x

- name: Run Zizmor
  env:
    ZIZMOR_EXE: ${{ steps.zizmor.outputs.exe }} # where zizmor is installed
  run: |
    "$ZIZMOR_EXE" ./
```

To install a given version, do the following:

```yaml
- name: Install Zizmor
  id: zizmor
  uses: NyanKiyoshi/actions/install-zizmor@v1.x.x
  with:
    # https://github.com/zizmorcore/zizmor/releases
    version: v1.24.1
    # Digest from 'zizmor-x86_64-unknown-linux-gnu.tar.gz'
    amd64-digest: a8000f3c683319a523d3b20df0e75457ba591f049cfcbfa98966631b56733c03
    # Digest from 'zizmor-aarch64-unknown-linux-gnu.tar.gz'
    aarch64-digest: d66e37ef8a375fb07939c630ebf9709a6e0f20242bdc3faf672a7ed97e0b768d

- name: Run Zizmor
  env:
    ZIZMOR_EXE: ${{ steps.zizmor.outputs.exe }} # where zizmor is installed
  run: |
    "$ZIZMOR_EXE" ./
```

Alternatively to `steps.zizmor.outputs.exe`, you can also add zizmor to the PATH:

```yaml
- name: Install Zizmor
  id: zizmor
  uses: NyanKiyoshi/actions/install-zizmor@v1.x.x

- name: Add to PATH
  env:
    ZIZMOR_DIR: ${{ steps.zizmor.outputs.install-dir }}
  run: |
    echo "$ZIZMOR_DIR" >> "$GITHUB_PATH"

- name: Run Zizmor
  run: |
    zizmor ./
```

[`install-zizmor`]: ./install-zizmor/action.yaml
