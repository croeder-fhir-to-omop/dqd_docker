FROM rocker/shiny:latest

# Python for the ETL
RUN apt-get update \
 && apt-get install -y python3 python3-pip \
 && rm -rf /var/lib/apt/lists/*

RUN pip3 install --no-cache-dir requests duckdb

# R packages
RUN Rscript -e "install.packages(c('duckdb', 'DBI', 'DatabaseConnector', 'DataQualityDashboard'), repos='https://cloud.r-project.org')"

# Copy ETL scripts and DDL
COPY matchbox_scripts/transforms.py matchbox_scripts/load_duckdb.py /etl/
COPY matchbox_scripts/*.json /etl/
COPY matchbox_scripts/ddl/ /etl/ddl/

# Copy DQD runner
COPY run_dqd.R /srv/shiny-server/run_dqd.R

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENV MATCHBOX_URL=http://matchbox:8080
ENV OMOP_DB_PATH=/omop/omop.ddb

EXPOSE 3838

ENTRYPOINT ["/entrypoint.sh"]
