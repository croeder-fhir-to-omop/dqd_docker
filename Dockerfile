FROM rocker/r-ver:latest

# Python for the ETL + Java for rJava/DatabaseConnector
RUN apt-get update \
 && apt-get install -y python3 python3-pip libcurl4-openssl-dev libssl-dev libxml2-dev default-jdk \
 && rm -rf /var/lib/apt/lists/* \
 && R CMD javareconf

RUN pip3 install --no-cache-dir --break-system-packages requests duckdb

# R packages — use PPM for pre-built Linux binaries, fall back to CRAN for missing
RUN Rscript -e " \
  options(repos = c(PPM = 'https://packagemanager.posit.co/cran/__linux__/noble/latest', CRAN = 'https://cloud.r-project.org')); \
  install.packages(c('shiny', 'DBI', 'duckdb', 'DatabaseConnector', 'remotes'))"
RUN Rscript -e "remotes::install_github('OHDSI/DataQualityDashboard')"

# Copy ETL scripts and DDL
COPY matchbox_scripts/transforms.py matchbox_scripts/load_duckdb.py matchbox_scripts/omop_to_csv.py /etl/
COPY matchbox_scripts/*.json /etl/
COPY matchbox_scripts/ddl/ /etl/ddl/

# Copy DQD runner and Shiny launcher
COPY dqd_docker/run_dqd.R /app/run_dqd.R
COPY dqd_docker/serve_dqd.R /app/serve_dqd.R

COPY dqd_docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENV MATCHBOX_URL=http://matchbox:8080
ENV OMOP_DB_PATH=/omop/omop.ddb
ENV DQD_RESULTS=/omop/dqd_results.json

EXPOSE 3838

ENTRYPOINT ["/entrypoint.sh"]
