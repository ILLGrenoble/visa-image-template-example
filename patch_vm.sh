#!/bin/bash
#
# Script to patch manifest files for use in a VM with nested virtualization.

# [Bash Strict Mode](http://redsymbol.net/articles/unofficial-bash-strict-mode/)
set -euo pipefail
IFS=$'\n\t'

save_manifests() {
  for file in ./templates/**/manifest.yml; do
    cp -p "$file"{,.BKP}
  done
}

restore_manifests() {
  for file in ./templates/**/manifest.yml; do
    mv "$file"{.BKP,}
  done
}

nested_virt() {
  IFS=$'\n' read -r -d '' KEY <<EOM
      qemuargs:
EOM
  IFS=$'\n' read -r -d '' VAL <<EOM
        - - "-cpu"
          - "host"
        - - "-enable-kvm"
          - ""
EOM

  for file in ./templates/**/manifest.yml; do
    if ! grep -q 'qemuargs' "$file"; then
      # insert $KEY after `type: qemu`
      sed -i "/type: qemu/a \\${KEY//$'\n'/\\n}" "$file"
    fi
    # insert $VAL after `qemuargs:`
    sed -i "/qemuargs:/a \\${VAL//$'\n'/\\n}" "$file"
  done
}

patch_files() {
  if grep -q 'hypervisor' /proc/cpuinfo; then # running inside a VM
    if grep -qE '(vmx|svm)' /proc/cpuinfo; then # nested virtualization supported
      save_manifests
      nested_virt
    fi
  else
    false
  fi
}

compare_files() {
  for file in ./templates/**/manifest.yml; do
    echo "$file"
    diff "$file"{.BKP,} || true # diff return a non-zero value when there are differences
  done
}

if ! ls ./templates/**/manifest.yml &>/dev/null; then
  echo "Can't find manifest files."
  false
fi

case ${1-} in
p | patch)
  if ls ./templates/**/manifest.yml.BKP &>/dev/null; then
    echo "Files have already been patched."
    false
  else
    if patch_files; then
      echo "Files have been patched successfully."
    else
      echo "Your system does not support nested virtualization or is not a VM."
      false
    fi
  fi
  compare_files
  ;;

r | restore)
  if ls ./templates/**/manifest.yml.BKP &>/dev/null; then
    restore_manifests
    echo "Manifest files have been restored."
  else
    echo "There are no files to restore."
    false
  fi
  ;;

*)
  cat <<'EOM'
Usage: patch_vm.sh <argument>

Argument:
  p|patch:    Patch the manifests files for use inside a VM with nested virtualization.
  r|restore:  Restore the original files.
EOM
  false
  ;;
esac
