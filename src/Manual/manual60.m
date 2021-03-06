.H 1 "Rules"
It is possible to prove quite complex things about programs with the
Verifier. 
In order to accomplish this, the user must define
.I "rule functions"
which represent the properties to be proven and must prove rules
about them using the 
.I "rule builder."
We will illustrate this with a simple example, going into considerable
detail on how to go about doing such things.
