DROP SCHEMA IF EXISTS projet CASCADE;
CREATE SCHEMA projet;
CREATE TABLE projet.formations (
	id_formations SERIAL PRIMARY KEY,
	nom VARCHAR(100) NOT NULL CHECK (nom<>''),
	prenom VARCHAR(100) NOT NULL CHECK (prenom<>'')
);
CREATE TABLE projet.etudiants (
	id_etudiant SERIAL PRIMARY KEY,
	nom VARCHAR(50) NOT NULL CHECK (nom<>''),
	prenom VARCHAR(50) NOT NULL CHECK (prenom<>''),
	mot_de_passe VARCHAR(50) NOT NULL CHECK (mot_de_passe<>''),
	code_bloc VARCHAR(10) REFERENCES projet.blocs (id_bloc) NOT NULL
);