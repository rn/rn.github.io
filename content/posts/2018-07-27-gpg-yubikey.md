---
title: "GnuPG and YubiKey"
date: 2018-07-27T11:07:40+01:00
---



This creates a master key and secondary keys. The latter are stored on
multiple YubiKeys. It mostly follows [this great
post](https://blog.josefsson.org/2014/06/23/offline-gnupg-master-key-and-subkeys-on-yubikey-neo-smartcard/)
with some additions from
[here](https://gist.github.com/ageis/5b095b50b9ae6b0aa9bf),
[here](https://github.com/drduh/YubiKey-Guide#purchase-yubikey). and
[here](https://lists.gt.net/gnupg/users/76764#76764).

Unless otherwise specified I use:
```
export GNUPGHOME=~/gnupg
mkdir $GNUPGHOME
chmod go-rwx $GNUPGHOME

export GNUPGBAK=~/gnupg-save
mkdir $GNUPGBAK
chmod go-rwx $GNUPGBAK
```

## Preparing the YubiKey

Note: The default admin pin is `12345678` and the default user pin is
`123456`. We start with a YubiKey after a factory reset (`gpg
--card-edit` -> `admin` -> `factory-reset`).

**Also, note that whenever you change YubiKeys in a computer it is important to execute `gpg --card-status`.**


We start by changing the admin and user PIN and set some user
information:

```sh
gpg --card-edit

# enter admin menu
admin

# Set Name
name

# Set login name
login

# Set language (en)
login

# Change Admin PIN (select 3 and 1)
passwd

```

Repeat the above for all YubiKeys


## Generating a primary root key

The primary key will just be used to create subkeys, so we create a
key with just certification capabilities.

```sh
gpg --expert --full-generate-key

# Select:   '(8) RSA (set your own capabilities)'
#   Toggle capabilities so that only 'Certify' is enabled
# Keysize:  4096
# Expiry:   0 (never)
# Name/Email
```

The new key has the id: `B7C208779E105381F1D0EF2444C8157162862E16`

Add more identities
```sh
gpg --edit-key B7C208779E105381F1D0EF2444C8157162862E16

adduid
# Add name/email (repeat multiple times)

uid 1
primary
# this sets the primary

save
```

Backup:
```sh
cp -a $GNUPGHOME $GNUPGHOME-backup-masterkey
```

## Create subkeys

This creates three subkeys which I use for signing, encryption, and
authentication. These are 4096 bit keys (which are supported on the
YubiKey 4).


```sh
gpg --expert --edit-key B7C208779E105381F1D0EF2444C8157162862E16

# Signing key
addkey
# Select:  (4) RSA (sign only)
# Keysize: 4096
# Expiry:  0
# -> rsa4096/C6CE45B0EACFC0F3

# Encryption key
addkey
# Select:  (6) RSA (encrypt only)
# Keysize: 4096
# Expiry:  0
# -> rsa4096/3F5F19349916A287

# Authentication key
addkey
# Select:  (8) RSA (set your own capabilities)
#   Disable sign with:        (S) Toggle the sign capability
#   Disable encrypt with:     (E) Toggle the encrypt capability
#   Enable authenticate with: (A) Toggle the authenticate capability
# Keysize: 4096
# Expiry:  0
# -> rsa4096/2E30AC9E42565BEA

save
```

We have now created all the keys we need. Time to back them up. Keep
the backup somewhere save!

Backup:
```sh
gpg -a --export-secret-keys B7C208779E105381F1D0EF2444C8157162862E16 > $GNUPGBAK/mastersubkey.sec
gpg -a --export-secret-subkeys B7C208779E105381F1D0EF2444C8157162862E16 > $GNUPGBAK/subkeys.sec
gpg -a --export B7C208779E105381F1D0EF2444C8157162862E16 > $GNUPGBAK/pubkey.asc
cp $GNUPGHOME/openpgp-revocs.d/B7C208779E105381F1D0EF2444C8157162862E16.rev $GNUPGBAK
cp -a $GNUPGHOME $GNUPGHOME-backup-mastersubkeys
```

## Move subkeys YubiKey

```sh
gpg --edit-key B7C208779E105381F1D0EF2444C8157162862E16

toggle

# Move signing key (1 in this sequence)
key 1
keytocard
key 1

# Move encryption key (2 in this sequence)
key 2
keytocard
key 2

# Move authentication key (3 in this sequence)
key 3
keytocard
key 3
```

Now, it is **important** to hit `ctrl-c` and **not** save as we are
going to repeat the move to YubiKey for each of the YubiKey and only
on the last one say **save**.


### Copy keys to other YubiKeys

Restore the backup 
```sh
rm -r $GNUPGHOME
cp -r $GNUPGHOME-backup-mastersubkeys $GNUPGHOME
```

And then repeat the steps above
