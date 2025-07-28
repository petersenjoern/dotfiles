llm --system "Use the help output to generate a 'repomix' command to achieve the user's objective(s). Only return the command, no other text.\n$(repomix --help | sed 's/\$/\\$/g')" \
 --save repomix
