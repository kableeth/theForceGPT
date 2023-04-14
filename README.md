# Salesforce OpenAI Integration

This repository contains a Salesforce Apex class and Flow components that integrate with the OpenAI API using GPT-3.5 Turbo. The integration allows users to generate text based on provided prompts and fetch record information from Salesforce objects, such as Account or Contact.

## Features

- Prompt ChatGPT with query results from Accounts & Contacts. (More objects on roadmap)
- Generate text based on provided prompts and context using OpenAI's GPT-3.5 Turbo.
- Draft follow-up emails using user signature and email examples.
- Customizable special field handling to prevent data leaks or errors.
- Flow components for seamless integration within Salesforce Flows.

## Prerequisites

To use this integration, you will need:

- An OpenAI API key.

## Installation

1. Install the package to your org. <a href="https://login.salesforce.com/packaging/installPackage.apexp?p0=04tEm0000001yBp&isdtp=p1">(Production & Developer Install Link | </a> <a href="https://test.salesforce.com/packaging/installPackage.apexp?p0=04tEm0000001yBp&isdtp=p1">Sandbox Install Link)</a> 
2. Enter OpenAI API key into custom settings named "OpenAI Secret Key"
4. Configure any special fields settings in the custom metadata type labeled "OpenAI Chat Settings Special Field". Add any fields to ignore using the field api name and "Ignore" action
5. Activate & drop the "Open AI Send Message" Screen flow on the contact or record you'd like to use the component form.
6. Check "Pass record Id into this variable" on the Flow properties of the Lightning App Builder
7. Create a Sample Sales Email record with an example email that you would like the "Draft F/U Sales Email" to use as inspiration.

## Usage

<a href="https://www.loom.com/share/f6b40ecf1b42415595f9ab3ab00faacd"> Loom video on usages</a>
