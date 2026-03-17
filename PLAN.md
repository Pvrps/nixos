# Windows 11 Dual Boot Implementation Plan

This document outlines the steps to safely install Windows 11 alongside your existing NixOS installation, keeping NixOS as the primary operating system.

## 1. Declarative NixOS Changes (Update Disko)

Before touching the disk, we must update your NixOS configuration so `disko` knows not to overwrite the new Windows partition in the future.

1. Open your terminal in NixOS.
2. Edit your `disko.nix` file:
   ```bash
   nano /persist/etc/nixos/systems/desktop/disko.nix
   ```
3. Find the `root` partition block (around line 19) and change `size = "100%";` to `size = "1.5T";`.

   **Before:**
   ```nix
           root = {
             size = "100%";
             content = {
               type = "btrfs";
   ```
   **After:**
   ```nix
           root = {
             size = "1.5T";
             content = {
               type = "btrfs";
   ```
4. Save the file and exit.
5. Add and commit the change to Git (NixOS flakes require files to be tracked):
   ```bash
   cd /persist/etc/nixos
   git add systems/desktop/disko.nix
   git commit -m "chore(disko): restrict root partition size to 1.5T for dual boot"
   ```

---

## 2. Shrink the NixOS Partition (Live USB)

Because your NixOS root partition (`nvme0n1p2`) contains an active swapfile and mounted BTRFS subvolumes, you cannot shrink it while NixOS is running.

1. Create a **GParted Live USB** (or use an Ubuntu Live USB).
2. Reboot your computer and boot into the Live USB.
3. Open GParted.
4. Locate your NVMe drive (`/dev/nvme0n1`).
5. Right-click the second partition (`nvme0n1p2`, the large BTRFS partition) and select **Resize/Move**.
6. Shrink the partition so that there is roughly **300 GiB of "Free space following"** the partition.
7. Click the **Green Checkmark** at the top to apply the operations. Wait for it to finish.
8. Shut down the computer.

---

## 3. Install Windows 11

Windows will be installed into the empty space you just created. It will automatically detect your existing `512M` EFI partition (`/boot`) and place its bootloader there alongside NixOS.

1. Insert your **Windows 11 Installation USB**.
2. Boot into the Windows installer.
3. Proceed through the initial setup screens until you reach the installation type.
4. Choose **Custom: Install Windows only (advanced)**.
5. You will see a list of partitions. Look for the **"Unallocated Space"** (it should be roughly 300GB).
6. Select the **Unallocated Space** and click **Next**.
   *Note: Do NOT manually create new partitions or format existing ones. Let Windows handle the unallocated space automatically.*
7. Windows will install and reboot your computer a few times. Let it finish setting up completely.

---

## 4. Restore the Boot Order

During installation, Windows will hijack your motherboard's UEFI boot order and set "Windows Boot Manager" as the primary default. We need to change it back to `systemd-boot` so you can choose your OS.

1. Restart your computer.
2. Immediately mash your BIOS/UEFI key (usually `F2`, `F12`, or `Del`) to enter the firmware settings.
3. Navigate to the **Boot** or **Boot Priority** tab.
4. Move **"Linux Boot Manager"** (or simply your NVMe drive name, depending on the motherboard) to the very top, above "Windows Boot Manager".
5. Save changes and exit (usually `F10`).

## 5. Verification

1. When your computer restarts, you should see the `systemd-boot` menu (a black screen with white text).
2. You will now see two entries:
   * **NixOS** (and previous generations)
   * **Windows Boot Manager**
3. Select "Windows Boot Manager" to boot into Windows 11, or select "NixOS" to boot into your Linux system.
