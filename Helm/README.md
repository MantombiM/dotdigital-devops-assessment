# Helm Assessment

This directory contains the Helm assessment solution.

## Structure

- `part1/` - initial chart implementation for deploying one selected site
- `part2/` - chart evolved to support regional hostname rules
- `part3/` - chart evolved to support site, region, and environment combinations

## Chart name

The chart is named `multi-site-app` to reflect that this task is a generic multi-site Helm exercise, separate from the Azure DevOps voting app task.

## Notes

A simple placeholder container image is used for the Helm exercise so the focus remains on Helm templating, values design, and ingress behavior.