# Hedgedoc Appliance Example

This directory contains an example of how to build a Hedgedoc appliance that gets its configuration via an extension image built using `naext`.
Furthermore there is an IaC deployment provided that shows how this can be integrated into operations.

There are two relevant derivations:

1.  `appliance`: A base image containing Hedgedoc and all its static dependencies.
2.  `extensionImage`: A parameterizable configuration extension that can be applied to the appliance image at runtime.

## IaC Deployment

The IaC deployment will:

1.  Create an OpenStack instance from the `applianceImage`.
2.  Supply SSH trusted keys to the instance to be a via `cloud-init`.
3.  Copy the `extensionImage` to the instance via SSH.
4.  Apply the `extensionImage` on the instance.
