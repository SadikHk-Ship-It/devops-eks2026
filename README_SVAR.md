Ceatsheet comands:

mvn spring-boot:run

health-sjekk:
curl http://localhost:8080/api/health

analyse:
curl -F "image=@samples/sample_image.png" \
http://localhost:8080/api/analyze

docker:
docker build -t wishifai .

docker run -p 9999:8080 \
-e AWS_ACCESS_KEY_ID="$(aws configure get aws_access_key_id)" \
-e AWS_SECRET_ACCESS_KEY="$(aws configure get aws_secret_access_key)" \
-e AWS_REGION="eu-west-1" \
-e S3_BUCKET="wishifai-29" \
wishifai

test docker versjon:

curl http://localhost:9999/api/health

curl -F "image=@samples/sample_image.png" \
http://localhost:9999/api/analyze

terraform:

cd infra
terraform init
terraform plan 

email@noe.no se resultatet i docs mappen som inneholder bilder av email og dashboard

terraform apply

Test AWS:

curl https://de-86f54205009c4060b27afe80d937f8df.ecs.eu-west-1.on.aws/api/health

curl -F "image=@samples/sample_image.png" \
https://de-86f54205009c4060b27afe80d937f8df.ecs.eu-west-1.on.aws/api/analyze

observer:

for i in {1..5}
do
  curl -F "image=@samples/sample_image.png" \
  https://de-86f54205009c4060b27afe80d937f8df.ecs.eu-west-1.on.aws/api/analyze
done

aws cloudwatch list-metrics --namespace Wishifai 

ryde opp: 

cd infra
terraform destroy -var="alarm_email=<din-epost>"



Oppgave 1A

Hva gjorde jeg?

Jeg containeriserte Spring Boot-applikasjonen ved hjelp av en multi-stage Dockerfile. I første byggefase brukes Maven og Eclipse Temurin JDK 21 til å bygge applikasjonen og generere en kjørbar JAR-fil. I andre byggefase brukes et lettere Eclipse Temurin JRE 21-image som kun inneholder den ferdige JAR-filen.

Containeren kjører applikasjonen som en egen ikke-root-bruker og eksponerer port 8080. Ved kjøring brukes portmapping fra port 9999 på vertsmaskinen til port 8080 i containeren slik at sensor kan teste applikasjonen på localhost:9999.

Hvorfor valgte jeg denne løsningen?

Jeg valgte en multi-stage build fordi det reduserer størrelsen på det ferdige imaget og sørger for at Maven, byggefiler og kildekode ikke blir med til produksjon. Dette gir et mindre image, raskere deploy og et redusert angrepsområde.

Jeg valgte også å kjøre containeren som en egen ikke-root-bruker for å følge sikkerhetsprinsippet om minste privilegium.

Oppgave 1B

Hva gjorde jeg?

Jeg opprettet en GitHub Actions-workflow som automatisk kjører ved push til main. Workflowen bygger Docker-imaget, logger inn mot Amazon ECR og publiserer imaget til ECR-repositoriet devops-eks2026.

AWS-legitimasjon lagres som GitHub Secrets og benyttes av workflowen ved autentisering mot AWS.

Tagging-strategi

Jeg bruker både latest og commit-SHA som tags.

latest gjør det enkelt å hente siste versjon av imaget, mens commit-SHA gjør det mulig å spore nøyaktig hvilken Git-commit som er deployet. Dette gjør feilsøking enklere og gjør det mulig å rulle tilbake til en tidligere versjon dersom en ny deploy fører til feil.

Oppgave 2A

Infrastruktur

Infrastrukturen er definert som kode ved hjelp av Terraform. Terraform oppretter en S3-bucket for lagring av opplastede bilder, en ECS Express-tjeneste for kjøring av applikasjonen og nødvendige IAM-ressurser.

Bucketen som opprettes er: wishifai-29

Terraform benytter variabler for region, kandidatnummer og image-tag, og eksponerer relevante verdier gjennom outputs.

ECS Express

Applikasjonen deployeres til ECS Express og bruker Docker-imaget som tidligere ble bygget og publisert til ECR.

Terraform konfigurerer følgende: Docker-image fra ECR offentlig URL health check mot /api/health
miljøvariablene S3_BUCKET og AWS_REGION
Tjenesten eksponeres via følgende offentlige endpoint: https://de-86f54205009c4060b27afe80d937f8df.ecs.eu-west-1.on.aws

Jeg valgte ECS Express fordi tjenesten reduserer mengden infrastruktur som må administreres manuelt, samtidig som den gir en enkel måte å kjøre containere i AWS.

IAM

Jeg opprettet en egen ECS Task Role: wishifai-task-role-29

Task-rollen gir kun tilgangene som applikasjonen faktisk trenger:
s3:GetObject
s3:PutObject
rekognition:DetectLabels
bedrock:InvokeModel

Oppgave 2B

Remote State

Terraform-state lagres i den delte S3-backenden: pgr301-terraform-state

med nøkkelen: wishifai/29/terraform.tfstate

Jeg migrerte Terraform-state fra lokal lagring til S3-backenden slik at infrastrukturen kan administreres av flere utviklere uten risiko for at lokale state-filer kommer ut av synk.

Remote state gjør også at Terraform kan brukes på tvers av maskiner og CI/CD-systemer.

Oppgave 2C

GitHub Actions og Terraform

Workflowen ble utvidet med en egen Terraform-jobb som kjører etter Docker-jobben ved hjelp av:
needs: docker
Terraform-jobben utfører:
terraform fmt -check
terraform init
terraform validate
terraform apply

Forskjøvet kjøring sikrer at Terraform alltid deployer infrastrukturen basert på det imaget som nettopp ble bygget og publisert til ECR.

Hvorfor Terraform kjører etter Docker

Terraform-tjenesten refererer til Docker-imaget som ligger i ECR. Dersom Terraform hadde kjørt før Docker-jobben kunne infrastrukturen blitt deployet med et image som ikke eksisterer ennå.

Ved å kjøre Docker-jobben først sikres det at riktig image er tilgjengelig før Terraform starter deployen.

Oppgave 3A

Applikasjonen ble instrumentert med Micrometer og CloudWatch.

Jeg implementerte følgende egne metrikker:
wishifai.rekognition.latency; måler tiden brukt på kall til AWS Rekognition.
wishifai.bedrock.latency; måler tiden brukt på kall til AWS Bedrock.
wishifai.suggestions.generated; er en forretningsmetrikk som teller hvor mange gaveforslag som genereres.

Metrikkene publiseres til AWS CloudWatch under namespace Wishifai.

Oppgave 3B

Dashboard og alarm er definert som Terraform-kode i infra/dashboard.tf og infra/alarm.tf. Jeg opprettet et CloudWatch-dashboard kalt Wishifai-29 som samler metrikker fra applikasjonen, infrastrukturen og forretningsdelen av løsningen.
Som business-metrikk valgte jeg: wishifai.suggestions.generated.count

Denne teller hvor mange gaveforslag som blir generert. Jeg valgte den fordi den sier noe om hvor mye verdi applikasjonen faktisk leverer til brukerne og hvor mye tjenesten brukes.
For applikasjonen overvåker jeg både: wishifai.rekognition.latency.avg og wishifai.bedrock.latency.avg


Disse måler responstiden til de to AI-tjenestene. Under testing lå Rekognition på omtrent 1 sekund, mens Bedrock lå på omtrent 14,6 sekunder. Dette gjorde det enkelt å identifisere at mesteparten av ventetiden kommer fra Bedrock. Jeg overvåker også HTTP-latency, JVM-minne og GC-pausetid for å kunne oppdage problemer i selve applikasjonen.

På infrastruktursiden overvåkes CPU- og minnebruk for ECS-tjenesten. Under testingen var begge verdiene lave og stabile. Dette viser at tregheten brukeren opplever ikke skyldes containeren eller infrastrukturen, men kallene mot Bedrock.

Jeg opprettet også alarmen: wishifai-bedrock-latency-high-29
som overvåker: wishifai.bedrock.latency.avg

Alarmen sender varsling på e-post dersom gjennomsnittlig Bedrock-latency overstiger 8 000 ms i 2 perioder på 5 minutter. Jeg valgte Bedrock-latency fordi dette er den tregeste delen av løsningen og derfor har størst påvirkning på brukeropplevelsen.

Siden gjennomsnittlig Bedrock-latency under testing var omtrent 14,6 sekunder, ligger den over terskelverdien. Alarmen vil derfor gå av under normal bruk, noe som bekrefter at tjenesten i dag er tregere enn ønsket. Dette gir et konkret svar på grunderens bekymring rundt responstid.

Alarmen ble testet ved hjelp av: aws cloudwatch set-alarm-state
og jeg mottok e-post både da alarmen gikk til ALARM-status og da den gikk tilbake til OK-status. Dette bekreftet at varslingen fungerer som forventet.

En begrensning med alarmen er at den kun overvåker responstid. Den kan oppdage treghet i systemet, men den kan ikke avgjøre om gaveforslagene som genereres er gode eller passende. Dette diskuteres nærmere i oppgave 4.

Under arbeidet oppdaget jeg at JVM-widgeten først var tom. Årsaken var at Micrometer legger suffikset .value på gauges i CloudWatch. Metrikken heter derfor:
jvm.memory.used.value og ikke: jvm.memory.used

Jeg fant riktig metrikknavn ved å bruke: aws cloudwatch list-metrics --namespace Wishifai
Skjermbilder av dashboardet og alarmvarslingen er lagret i:
docs/dashboard.png
docs/alarm-epost.png

Oppgave 4

Generativ AI gjør testing og overvåking mer utfordrende enn tradisjonell programvare. En applikasjon kan fungere teknisk korrekt samtidig som den gir dårlige eller feil svar til brukeren.

I Wishifai bruker applikasjonen AWS Bedrock til å generere gaveforslag. Selv om alle API-kall lykkes og systemet returnerer HTTP 200, betyr ikke det nødvendigvis at forslaget som genereres er relevant eller riktig. Dette gjør at man må kontrollere mer enn bare teknisk funksjonalitet.

Testing

Tradisjonelle tester baserer seg ofte på at samme input gir samme output. Dette gjelder ikke nødvendigvis for generative AI-modeller. Derfor må man teste kvaliteten på svarene på andre måter.
En mulig løsning er å bruke et sett med testbilder og kontrollere at svarene oppfyller bestemte krav. For eksempel kan man sjekke at responsen er gyldig JSON, at det genereres et rimelig antall forslag, og at forslaget ikke inneholder upassende innhold.

Under arbeidet med oppgaven opplevde jeg at Bedrock begynte å returnere vanlig tekst i stedet for JSON etter at prompten ved et uhell ble endret. Applikasjonen kjørte fortsatt, men parsingen feilet. Dette viser hvorfor automatiserte tester er viktige også for AI-baserte systemer.

Kontinuerlig leveranse

Når man bruker generativ AI, kan både modell og prompt påvirke resultatet uten at selve programkoden endres. Derfor bør promptene behandles som kode og lagres i Git sammen med resten av prosjektet.
Endringer i prompt eller modell bør testes gjennom samme pipeline som vanlig kode. Dette gjør det enklere å oppdage problemer og eventuelt rulle tilbake til en tidligere versjon.

Overvåking

I oppgave 3 overvåket jeg blant annet:
Bedrock-latency
Rekognition-latency
CPU-bruk
Minnebruk
Antall genererte gaveforslag

Disse metriktene gjør det mulig å oppdage tekniske problemer. Samtidig sier de lite om kvaliteten på svarene som genereres.
For å overvåke kvalitet kunne man for eksempel samle inn brukerfeedback eller registrere hvor ofte brukerne mener forslagene er irrelevante. Dette ville gitt bedre innsikt i om AI-løsningen faktisk fungerer slik den er tenkt.

Risikovurdering

Hvor strenge kontrollmekanismer man trenger avhenger av konsekvensene av feil. I Wishifai er konsekvensen begrenset til at brukeren får et dårlig gaveforslag, og risikoen er derfor lav.
I systemer som gir medisinske, juridiske eller økonomiske råd er konsekvensene langt større. Der bør mennesker kontrollere endringer i både modeller og prompt før de tas i bruk, og overvåkingen må være betydelig strengere.

Mennesker i prosessen

Automatisering er nyttig for å oppdage tekniske feil raskt, men mennesker bør fortsatt være involvert ved større endringer. Dette gjelder spesielt ved bytte av modell, endring av prompt eller vurdering av kvaliteten på genererte svar.
Jo større konsekvensene av en feil er, desto viktigere er det at et menneske kvalitetssikrer resultatene før de brukes i produksjon.

