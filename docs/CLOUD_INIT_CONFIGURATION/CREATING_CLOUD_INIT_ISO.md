# 5.3 Creating Cloud-init ISO

## Create Configuration Directory

```bash
# Create cloud-init directory
mkdir cloud-init-data
cd cloud-init-data

# Create your user-data and meta-data files
# (use configurations from section 5.2)
```

## Generate ISO with genisoimage

```bash
sudo genisoimage -output cloud-init.iso \
  -volid cidata \
  -joliet \
  -rock \
  user-data meta-data
```

## Generate ISO with xorriso

```bash
xorriso -as mkisofs \
  -o cloud-init.iso \
  -V cidata \
  -J -r \
  user-data meta-data
```

## Including network-config

If using a separate network-config file:

```bash
sudo genisoimage -output cloud-init.iso \
  -volid cidata \
  -joliet \
  -rock \
  user-data meta-data network-config
```

## Verification

After creating the ISO, verify its contents:

```bash
# Mount and check contents
sudo mount -o loop cloud-init.iso /mnt
ls -la /mnt
cat /mnt/user-data
sudo umount /mnt
```

## Usage

1. Attach the ISO as a virtual CD/DVD drive
2. Boot the system
3. Cloud-init will detect the NoCloud datasource
4. Configuration will be applied automatically

For physical servers, burn the ISO to a CD or use a virtual media feature (iLO, iDRAC, IPMI).
