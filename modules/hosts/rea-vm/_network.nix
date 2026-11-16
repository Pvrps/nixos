# Addresses shared by the rea-vm guest and the host side
# (modules/nixos/rea-vm.nix). Underscore prefix: not a NixOS module.
{
  tap = "vm-rea";
  mac = "02:00:00:88:00:02";
  prefixLength = 24;
  hostAddress = "10.88.0.1";
  guestAddress = "10.88.0.2";
  # Public resolvers, so the guest needs nothing from the host or the LAN.
  nameservers = ["1.1.1.1" "9.9.9.9"];
  # AF_VSOCK address; the host reaches the guest's sshd over vsock only.
  vsockCid = 88;
  # OpenSnitch UI on the host; the guest daemon reports connections here.
  opensnitchPort = 50051;
}
