#!/bin/bash
function tell {
  echo -e "\033[103;30m i > $1 \033[0m"
}
function ask {
  printf "\033[101;97m???>$1... \033[0m"
  read -n 1
}
tell "stashing whatever work you have pending"
git stash # make sure that whatever work you have pending is saved
tell "checking out demo"
git checkout demo
git checkout -b __testing_ci__
tell "creating a test workflow"
printf '
name: Test
on: push
jobs:
  List-APIs:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout the git repository
        uses: actions/checkout@v2
      - name: List apis known to APIM
        uses: Axway/presales-apim-cli-action@v0
        env:
          APIM_USER: ${{ secrets.APIM_USER }}
          APIM_PASS: ${{ secrets.APIM_PASS }}
          APIM_HOST: ${{ secrets.APIM_HOST }}
          APIM_PORT: ${{ secrets.APIM_PORT }}
        with:
          command: api get
' > .github/workflows/test.yml
tell "pushing it and crossing fingers"
git add .github/workflows/test.yml
git commit -m "testing ci"
git push origin __testing_ci__:__testing_ci__
tell "You can now go to your github interface to see the workflow"
tell "Please allow some minutes for Github to pick up your workflow"
ask "Type any key to revert our test"
tell "removing our test branch"
git checkout demo
git push -f origin :__testing_ci__
git branch -D __testing_ci__
tell "You are now on branch demo."
tell "You can go back where you were and issue 'git stash pop' to retrieve your work in progress"