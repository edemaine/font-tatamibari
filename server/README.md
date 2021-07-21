# Server for Tatamibari Design Tool

This directory is a CGI wrapper for the
[Tatamibari solver](https://github.com/jbosboom/tatamibari-solver),
which uses the Python Z3 library to find all (approximate) solutions
to a Tatamibari puzzle.
It also includes a copy of [`tatamibari_solver.py`](tatamibari_solver.py)
from that repository.

To get it running, you need a CGI web server (e.g. Apache) with the following
installed:

* Python 3.6+
* Z3
* `pip3 install z3-solver`
* `pip3 install psutil`

Use the included `.htaccess` file for Apache.

Then you can point [`tatamibari.py`](../tatamibari.py) to your server,
and open `design.html` as built from [design.pug](../design.pug).
