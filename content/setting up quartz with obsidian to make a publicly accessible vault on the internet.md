---
title: setting up quartz with obsidian to make a publicly accessible vault on the internet
tags:
  - child
---
#### **make sure you got nodeJS, git & obsidian installed and have a github account beforehand**
- go to the folder where where you wanna keep the vault 
- git clone the quartz repo and do this goofy ahh stuff: 
```sh fold
git clone https://github.com/jackyzha0/quartz.git
mv quartz vaultName
cd vaultName
npm i
npx quartz create
```
- create a github repo (no readme or lisence or anything just a bare repo) and copy the remote link
- back to the terminal again:
```sh fold title:dob
git remote -v
git remote set-url origin REMOTE-URL
git remote add upstream https://github.com/jackyzha0/quartz.git (for the upstream. it should already be there but just in case)
npx quartz sync --no-pull
```
- open the folder as a vault and set it up as you usually would 
- terminal againnnnnn: 
```sh fold title:dob
npx quartz sync
npx quartz build --serve (should shit out a localhost_8080 link that will give a basic preview of a barebones hosted page)
```
- now we actually host the thing with github pages
- terminal again yayyyyy:
```sh fold title:dob
cd .\.github\workflows\
notepad deploy.yml
```
- then paste this in and save:
```yml fold title:yes
name: Deploy Quartz site to GitHub Pages
 
on:
  push:
    branches:
      - v4
 
permissions:
  contents: read
  pages: write
  id-token: write
 
concurrency:
  group: "pages"
  cancel-in-progress: false
 
jobs:
  build:
    runs-on: ubuntu-22.04
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0 # Fetch all history for git info
      - uses: actions/setup-node@v4
        with:
          node-version: 22
      - name: Install Dependencies
        run: npm ci
      - name: Build Quartz
        run: npx quartz build
      - name: Upload artifact
        uses: actions/upload-pages-artifact@v3
        with:
          path: public
 
  deploy:
    needs: build
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    runs-on: ubuntu-latest
    steps:
      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v4
```
- go to the github repo and go to settings>pages and set Build and deployment source to `github actions`
- more terminal yay fun:
```sh fold title:yes
cd ../..
npx quartz sync
```
- now just do `npx quartz sync` when you make changes ig. or just use the obsidian git plugin and do it that way