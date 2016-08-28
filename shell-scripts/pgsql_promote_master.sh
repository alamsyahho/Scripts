#!/bin/bash

su - postgres -c "/usr/pgsql-9.3/bin/pg_ctl promote"
