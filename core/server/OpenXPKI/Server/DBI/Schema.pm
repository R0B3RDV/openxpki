## OpenXPKI::Server::DBI::Schema
##
## Written by Michael Bell for the OpenXPKI project 2005
## Copyright (C) 2005 The OpenXPKI Project

use strict;
use warnings;
use utf8;

package OpenXPKI::Server::DBI::Schema;

use OpenXPKI::Exception;

my %SEQUENCE_of = (
    CRL            => "seq_crl",
    CSR            => "seq_csr",
    CSR_ATTRIBUTES => "seq_csr_attributes",
    CERTIFICATE    => "seq_certificate",
    CERTIFICATE_ATTRIBUTES => "seq_certificate_attributes",
    CRR            => "seq_crr",
    AUDITTRAIL     => "seq_audittrail",
    GLOBAL_KEY_ID  => "seq_global_id",     # ??? FIXME - remove it?
    DATAEXCHANGE   => "seq_dataexchange",
    WORKFLOW       => "seq_workflow",    
    WORKFLOW_HISTORY => "seq_workflow_history",
    APPLICATION_LOG => "seq_application_log",
    );

my %COLUMN_of = (
    PKI_REALM                => "pki_realm",
    CA                       => "ca_name",
    ISSUING_CA               => "issuing_ca",
    ISSUING_PKI_REALM        => "issuing_pki_realm",  # FIXME: remove this
    ISSUER_IDENTIFIER        => "issuer_identifier",
    ISSUER_DN                => "issuer_dn",
    ALIAS                    => "alias",
    IDENTIFIER               => "identifier",
    CERTIFICATE_IDENTIFIER   => "identifier",
    SUBJECT_KEY_IDENTIFIER   => "subject_key_identifier",
    AUTHORITY_KEY_IDENTIFIER => "authority_key_identifier",

    SUBMIT_DATE           => "submit_date",
    APPROVAL_DATE         => "approval_date",
    TYPE                  => "format",
    DATA                  => "data",

    CREATOR               => 'creator',
    CREATOR_ROLE          => 'creator_role',
    REASON_CODE           => "reason_code",
    INVALIDITY_TIME       => 'invalidity_time',
    COMMENT               => 'crr_comment',
    HOLD_CODE             => 'hold_code',
    REVOCATION_TIME       => 'revocation_time',

    GLOBAL_KEY_ID         => "global_id",
    OBJECT_ID             => "object_id",
    CERTIFICATE_SERIAL    => "cert_key",
    REVOKE_CERTIFICATE_SERIAL => "cert_key",
    CSR_SERIAL            => "req_key",
    CRR_SERIAL            => "crr_key",
    CRL_SERIAL            => "crl_key",
    AUDITTRAIL_SERIAL     => "audittrail_key",
    APPLICATION_LOG_SERIAL  => "application_log_id",  
    DATA_SERIAL           => "data_key",
    PRIVATE_SERIAL        => "private_key",
    SIGNATURE_SERIAL      => "signature_key",
    LOCK_SERIAL           => "global_id",
    DATAEXCHANGE_SERIAL   => "dataexchange_key",
    WORKFLOW_SERIAL       => "workflow_id",
    WORKFLOW_VERSION_SERIAL  => "workflow_version_id",
    WORKFLOW_HISTORY_SERIAL  => "workflow_hist_id",
    GROUP_ID              => "group_id",
    PART_ID               => "part_id",
    
    ATTRIBUTE_SERIAL      => 'attribute_key',
    ATTRIBUTE_KEY         => 'attribute_contentkey',
    ATTRIBUTE_VALUE       => 'attribute_value',
    ATTRIBUTE_SOURCE      => 'attribute_source',
    SUBJECT               => "subject",
    EMAIL                 => "email",
    RA                    => "ra",
    LAST_UPDATE           => "last_update",
    NEXT_UPDATE           => "next_update",
    PUBLICATION_DATE      => "publication_date",
    PROFILE               => "profile",
    PUBKEY                => "public_key",
    NOTAFTER              => "notafter",
    NOTBEFORE             => "notbefore",
    SCEP_TID              => "scep_tid",
    LOA                   => "loa",
    PUBLIC                => "public_cert",

    STATUS                => "status",
    SERIAL                => "object_serial",
    TABLE                 => "object_type",
    UNTIL                 => "valid_until",
    SERVERID              => "server_id",
    EXPORTID              => "export_id",

    COLUMN_NAME           => "column_name",
    ARRAY_COUNTER         => "array_counter",

    TIMESTAMP             => "logtimestamp",
    MESSAGE               => "message",
    CATEGORY              => "category",
    LOGLEVEL              => "loglevel",
    PRIORITY              => "priority",

    KEYID                 => "keyid",
    CA_ISSUER_NAME        => "ca_issuer_name",
    CA_ISSUER_SERIAL      => "ca_issuer_serial",

    WORKFLOW_TYPE         => "workflow_type",
    WORKFLOW_STATE        => "workflow_state",
    WORKFLOW_LAST_UPDATE  => "workflow_last_update",

    #columns for pause/resume-Feature:
    WORKFLOW_PROC_STATE   => "workflow_proc_state",
    WORKFLOW_WAKEUP_AT    => "workflow_wakeup_at",
    WORKFLOW_COUNT_TRY    => "workflow_count_try",
    WORKFLOW_REAP_AT      => "workflow_reap_at",

    WORKFLOW_ACTION       => "workflow_action",
    WORKFLOW_DESCRIPTION  => "workflow_description",
    WORKFLOW_USER         => "workflow_user",
    WORKFLOW_HISTORY_DATE => "workflow_history_date",
    WORKFLOW_CONTEXT_KEY  => "workflow_context_key",
    WORKFLOW_CONTEXT_VALUE => "workflow_context_value",
    WORKFLOW_SESSION       => "workflow_session",
    WATCHDOG_KEY          => "watchdog_key",

    NAMESPACE             => "namespace",
    DATAPOOL_KEY          => "datapool_key",
    DATAPOOL_VALUE        => "datapool_value",
    ENCRYPTION_KEY        => "encryption_key",
    DATAPOOL_LAST_UPDATE  => "last_update",

    # generation id for alias groups
    GENERATION          => "generation",
    );


my $NAMESPACE;

my %TABLE_of = (

    CSR => { # this table contains what is requested, which might not
             # necessarily match what is in the DATA column
        NAME    => "csr",
        INDEX   => [ "PKI_REALM", "CSR_SERIAL" ],
        COLUMNS => [ "PKI_REALM", "CSR_SERIAL",
                     "TYPE",  # SPKAC, PKCS#10, IE...
             "DATA",  # the pkcs#10/spkac request
             "PROFILE",
             "LOA",
                     "SUBJECT",
             # "PUBKEY",
             # "RA",
        ],
        KEY => 'CSR_SERIAL'
    },

    # CSR attributes, e. g.
    # 'subject_alt_name'
    # "GLOBAL_KEY_ID",
    # "SCEP_TID"
    CSR_ATTRIBUTES => {
        NAME    => "csr_attributes",
        INDEX   => [ "ATTRIBUTE_SERIAL", "PKI_REALM", "CSR_SERIAL" ],
        COLUMNS => [ "ATTRIBUTE_SERIAL", "PKI_REALM", "CSR_SERIAL",
             "ATTRIBUTE_KEY",
             "ATTRIBUTE_VALUE",
                     "ATTRIBUTE_SOURCE", # "USER" | "OPERATOR" | "EXTERNAL"
        ],
        KEY => 'ATRRIBUTE_SERIAL'
    },
    
    CRR => {
        NAME    => 'crr',
        INDEX   => [ 'CRR_SERIAL', 'PKI_REALM', 'IDENTIFIER' ],
        COLUMNS => [ 'CRR_SERIAL', 'PKI_REALM', 'IDENTIFIER',
                     'CREATOR', 'CREATOR_ROLE', 'REASON_CODE',
                     'INVALIDITY_TIME', 'COMMENT', 'HOLD_CODE',
                     'REVOCATION_TIME',
                   ],
        KEY => 'CRR_SERIAL'                   
    },

    CERTIFICATE => {
        NAME    => "certificate",
        INDEX   => [ "ISSUER_IDENTIFIER", "CERTIFICATE_SERIAL" ],
        COLUMNS => [ "PKI_REALM", "ISSUER_DN", "CERTIFICATE_SERIAL",
             "ISSUER_IDENTIFIER", "IDENTIFIER",
                     # "GLOBAL_KEY_ID",
                     "SUBJECT",
                     "STATUS",
                     "SUBJECT_KEY_IDENTIFIER", "AUTHORITY_KEY_IDENTIFIER",
                     "NOTAFTER", "LOA", "NOTBEFORE", "CSR_SERIAL",
                     "PUBKEY", "DATA"
                   ],
        KEY => 'CERTIFICATE_SERIAL' # Automatic seq. generation on certificate might be a problem!                   
    },
    
    CERTIFICATE_ATTRIBUTES => {
        NAME    => "certificate_attributes",
        INDEX   => [ "ATTRIBUTE_SERIAL", "IDENTIFIER", ],
        COLUMNS => [ "ATTRIBUTE_SERIAL", "IDENTIFIER",
             "ATTRIBUTE_KEY",
             "ATTRIBUTE_VALUE",
        ],
        KEY => "ATTRIBUTE_SERIAL"
    },

    ALIASES => {
       NAME    => 'aliases',
       INDEX   => [ 'PKI_REALM', 'ALIAS' ],
       COLUMNS => [ 'IDENTIFIER', 'PKI_REALM', 'ALIAS', 'GROUP_ID','GENERATION', 'NOTAFTER', 'NOTBEFORE' ],
    },

    CRL => {
        NAME    => "crl",
        INDEX   => [ "PKI_REALM", "ISSUER_IDENTIFIER", "CRL_SERIAL" ],
        COLUMNS => [ "PKI_REALM", "ISSUER_IDENTIFIER", "CRL_SERIAL",
                     "DATA",
                     "LAST_UPDATE",
             "NEXT_UPDATE",
             "PUBLICATION_DATE",
        ],
        KEY => "CRL_SERIAL"
    },

    AUDITTRAIL => {
        NAME    => "audittrail",
        INDEX   => [ "AUDITTRAIL_SERIAL" ],
        COLUMNS => [ "AUDITTRAIL_SERIAL",
                     "TIMESTAMP",
                     "CATEGORY", "LOGLEVEL", "MESSAGE" ],
        KEY => "AUDITTRAIL_SERIAL"
    },
    APPLICATION_LOG => {
        NAME    => "application_log",
        INDEX   => [ "APPLICATION_LOG_SERIAL" ],
        COLUMNS => [ "APPLICATION_LOG_SERIAL",
                     "TIMESTAMP",
                     "WORKFLOW_SERIAL",
                     "CATEGORY", "PRIORITY", "MESSAGE" ],
        KEY => "APPLICATION_LOG_SERIAL"
    },

    SECRET => {
        NAME    => "secret",
        INDEX   => ["PKI_REALM", "GROUP_ID"],
        COLUMNS => ["PKI_REALM", "GROUP_ID", "DATA"]},
 
    WORKFLOW => {
        NAME    => "workflow",
        INDEX   => [ "WORKFLOW_SERIAL" ],
        COLUMNS => [ "WORKFLOW_SERIAL",
             "PKI_REALM",
             "WORKFLOW_TYPE",
             "WORKFLOW_STATE",
             "WORKFLOW_LAST_UPDATE",

             "WORKFLOW_PROC_STATE",
             "WORKFLOW_WAKEUP_AT",
             "WORKFLOW_COUNT_TRY",
             "WORKFLOW_REAP_AT",
             "WORKFLOW_SESSION",
             "WATCHDOG_KEY",
        ],
        KEY => "WORKFLOW_SERIAL",
    },

    WORKFLOW_HISTORY => {
        NAME    => "workflow_history",
        INDEX   => [ "WORKFLOW_HISTORY_SERIAL" ],
        COLUMNS => [ "WORKFLOW_HISTORY_SERIAL",
             "WORKFLOW_SERIAL",
             "WORKFLOW_ACTION",
             "WORKFLOW_DESCRIPTION",
             "WORKFLOW_STATE",
             "WORKFLOW_USER",
             "WORKFLOW_HISTORY_DATE",
        ],
        KEY => "WORKFLOW_HISTORY_SERIAL",
    },

    WORKFLOW_CONTEXT => {
        NAME    => "workflow_context",
        INDEX   => [ "WORKFLOW_SERIAL", "WORKFLOW_CONTEXT_KEY", ],
        COLUMNS => [ "WORKFLOW_SERIAL", "WORKFLOW_CONTEXT_KEY",
             "WORKFLOW_CONTEXT_VALUE",
        ]},


    WORKFLOW_ATTRIBUTES => {
        NAME    => "workflow_attributes",
        INDEX   => [ "WORKFLOW_SERIAL", "ATTRIBUTE_KEY", ],
        COLUMNS => [ "WORKFLOW_SERIAL",
             "ATTRIBUTE_KEY",
             "ATTRIBUTE_VALUE",
        ],
    },

    DATAPOOL => {
        NAME    => "datapool",
        INDEX   => [ "PKI_REALM", "NAMESPACE", "DATAPOOL_KEY", ],
        COLUMNS => [ "PKI_REALM",
             "NAMESPACE",
             "DATAPOOL_KEY",
             "DATAPOOL_VALUE",
             "ENCRYPTION_KEY",
             "NOTAFTER",
             "DATAPOOL_LAST_UPDATE",
        ]},

    );

my %INDEX_of = (
#    TABLE_COLUMN => {
#        NAME    => "table_colument_index",
#        TABLE   => "TABLE",
#        COLUMNS => [ "COLUMN" ]},
    CERTIFICATE_PKI_REALM => {
        NAME => "cert_pki_realm_index",
        TABLE => "CERTIFICATE",
        COLUMNS => [ "PKI_REALM" ]},
    CERTIFICATE_CSR_SERIAL => {
        NAME => "cert_csr_serial_index",
        TABLE => "CERTIFICATE",
        COLUMNS => [ "CSR_SERIAL" ]},
    CERTIFICATE_SUBJECT => {
        NAME => "cert_subject_index",
        TABLE => "CERTIFICATE",
        COLUMNS => [ "SUBJECT" ]},
    CERTIFICATE_IDENTIFIER => {
        NAME => "cert_identifier_index",
        TABLE => "CERTIFICATE",
        COLUMNS => [ "IDENTIFIER" ]},
    CERTIFICATE_STATUS => {
        NAME => "cert_status_index",
        TABLE => "CERTIFICATE",
        COLUMNS => [ "STATUS" ]},
    CERTIFICATE_ATTRIBUTES_KEY => {
        NAME => "cert_attributes_key_index",
        TABLE => "CERTIFICATE_ATTRIBUTES",
        COLUMNS => [ "ATTRIBUTE_KEY" ]},
    # disabled because the column is a LOB
    #CERTIFICATE_ATTRIBUTES_VALUE => {
    #    NAME => "cert_attributes_key_index",
    #    TABLE => "CERTIFICATE_ATTRIBUTES",
    #    COLUMNS => [ "ATTRIBUTE_VALUE" ]},
    CSR_SUBJECT => {
        NAME => "csr_subject_index",
        TABLE => "CSR",
        COLUMNS => [ "SUBJECT" ]},
    CSR_PROFILE => {
        NAME => "csr_profile_index",
        TABLE => "CSR",
        COLUMNS => [ "PROFILE" ]},
    WORKFLOW_PKI_REALM => {
        NAME => "workflow_pki_realm_index",
        TABLE => "WORKFLOW",
        COLUMNS => [ "PKI_REALM" ]},
    WORKFLOW_STATE => {
        NAME => "workflow_state_index",
        TABLE => "WORKFLOW",
        COLUMNS => [ "WORKFLOW_STATE" ]},
    WORKFLOW_TYPE => {
        NAME => "workflow_type_index",
        TABLE => "WORKFLOW",
        COLUMNS => [ "WORKFLOW_TYPE" ]},
    WORKFLOW_CONTEXT_KEY => {
        NAME => "workflow_context_key_index",
        TABLE => "WORKFLOW_CONTEXT",
        COLUMNS => [ "WORKFLOW_CONTEXT_KEY" ]},
    # disabled because the column is a LOB
    #WORKFLOW_CONTEXT_VALUE => {
    #    NAME => "workflow_context_value_index",
    #    TABLE => "WORKFLOW_CONTEXT",
    #    COLUMNS => [ "WORKFLOW_CONTEXT_VALUE" ]},
    WORKFLOW_HISTORY_WORKFLOW_SERIAL => {
        NAME => "workflow_history_workflow_serial_index",
        TABLE => "WORKFLOW_HISTORY",
        COLUMNS => [ "WORKFLOW_SERIAL" ]},
#    DATA_COLUMN_NAME => {
#        NAME    => "data_column_name_index",
#        TABLE   => "DATA",
#        COLUMNS => [ "COLUMN_NAME" ]},
#    DATA_GLOBAL_KEY_ID   => {
#        NAME    => "data_global_id_index",
#        TABLE   => "DATA",
#        COLUMNS => [ "GLOBAL_KEY_ID" ]},
#    DATA_GLOBAL_COLUMN => {
#        NAME    => "data_global_column_index",
#        TABLE   => "DATA",
#        COLUMNS => [ "GLOBAL_KEY_ID", "COLUMN_NAME" ]},
#    DATA_COLUMN_STRING => {
#        NAME    => "data_column_string_index",
#        TABLE   => "DATA",
#        COLUMNS => [ "COLUMN_NAME", "STRING" ]},

    CERTIFICATE_REALM => {
        NAME  => 'cert_realm_index',
        TABLE => 'CERTIFICATE',
        COLUMNS => [ 'PKI_REALM' ],
    },
    CERTIFICATE_CSRSERIAL_IDENTIFIER => {
        NAME  => 'cert_csrid_index',
        TABLE => 'CERTIFICATE',
        COLUMNS => [ 'CSR_SERIAL' ],
    },
    WORKFLOW_HISTORY_WFSERIAL => {
        NAME  => 'wf_hist_wfserial_index',
        TABLE => 'WORKFLOW_HISTORY',
        COLUMNS => [ 'WORKFLOW_SERIAL' ],
    },
    WORKFLOW_REALM => {
        NAME  => 'wf_realm_index',
        TABLE => 'WORKFLOW',
        COLUMNS => [ 'PKI_REALM' ],
    },
    WORKFLOW_CONTEXT_KEY => {
        NAME  => 'wf_context_key_index',
        TABLE => 'WORKFLOW_CONTEXT',
        COLUMNS => [ 'WORKFLOW_CONTEXT_KEY' ],
    },
    WORKFLOW_ATTRIBUTES_WORKFLOW_KEY => {
        NAME  => 'wf_attributes_key_index',
        TABLE => 'WORKFLOW_ATTRIBUTES',
        COLUMNS => [ 'WORKFLOW_SERIAL' ],
    },
    #### FIXME - not working as the autoinit stuff generates a LONGTEXT for ATTRIBUTE_VALUE
    #WORKFLOW_ATTRIBUTES_VALUE_KEY => {
    #    NAME  => 'wf_attributes_value_index',
    #    TABLE => 'WORKFLOW_ATTRIBUTES',
    #    COLUMNS => [ 'ATTRIBUTE_VALUE' ],
    #}
    );

sub new
{
    my $self = {};
    bless $self, "OpenXPKI::Server::DBI::Schema";
    return $self;
}

########################################################################

sub get_column
{
    my $self = shift;
    my $column = shift;

    __check_param($column);

    if (not exists $COLUMN_of{$column})
    {
        OpenXPKI::Exception->throw (
            message => "I18N_OPENXPKI_SERVER_DBI_SCHEMA_GET_COLUMN_UNKNOWN_COLUMN",
            params  => {"COLUMN" => $column});
    }

    return $COLUMN_of{$column};
}

########################################################################

sub get_tables
{
    return [ keys %TABLE_of ];
}

sub get_table_name
{
    my $self = shift;
    my $table = shift;

    __check_param($table);

    if (! exists $TABLE_of{$table})
    {
        OpenXPKI::Exception->throw (
            message => "I18N_OPENXPKI_SERVER_DBI_SCHEMA_GET_TABLE_NAME_UNKNOWN_TABLE",
            params  => {
        TABLE => $table,
        });
    }
    if (defined $NAMESPACE) {
    return $NAMESPACE . '.' . $TABLE_of{$table}->{NAME};
    } else {
    return $TABLE_of{$table}->{NAME};
    }
}

sub get_table_index
{
    my $self = shift;
    my $table = shift;

    __check_param($table);

    if (! exists $TABLE_of{$table})
    {
        OpenXPKI::Exception->throw (
            message => "I18N_OPENXPKI_SERVER_DBI_SCHEMA_GET_TABLE_INDEX_UNKNOWN_TABLE",
            params  => {
        TABLE => $table,
        });
    }

    return $TABLE_of{$table}->{INDEX};
}

sub get_table_columns
{
    my $self = shift;
    my $table = shift;

    __check_param($table);

    if (not exists $TABLE_of{$table})
    {
        OpenXPKI::Exception->throw (
            message => "I18N_OPENXPKI_SERVER_DBI_SCHEMA_GET_TABLE_COLUMNS_UNKNOWN_TABLE",
            params  => {
        TABLE => $table,
        });
    }

    return $TABLE_of{$table}->{COLUMNS};
}

########################################################################

sub get_sequences
{
    return [ keys %SEQUENCE_of ];
}

sub get_sequence_name
{
    my $self = shift;
    my $sequence = shift;

    __check_param($sequence);

    if (not exists $SEQUENCE_of{$sequence})
    {
        OpenXPKI::Exception->throw (
            message => "I18N_OPENXPKI_SERVER_DBI_SCHEMA_GET_SEQUENCE_NAME_UNKNOWN_SEQUENCE",
            params  => {
        SEQUENCE => $sequence,
        });
    }

    if (defined $NAMESPACE) {
    return $NAMESPACE . '.' . $SEQUENCE_of{$sequence};
    } else {
    return $SEQUENCE_of{$sequence};
    }
}

# return the name of the column used as sequence, can be undef
sub get_sequence_column {

    my $self = shift;
    my $table = shift;

    __check_param($table);
    
    return $TABLE_of{$table}->{KEY};
    
}

########################################################################

sub get_indexes
{
    return [ keys %INDEX_of ];
}

sub get_index_name
{
    my $self = shift;
    my $index = shift;

    __check_param($index);

    if (not exists $INDEX_of{$index})
    {
        OpenXPKI::Exception->throw (
            message => "I18N_OPENXPKI_SERVER_DBI_SCHEMA_GET_INDEX_NAME_UNKNOWN_INDEX",
            params  => {
        INDEX => $index,
        });
    }

    return $INDEX_of{$index}->{NAME};
}

sub get_index_table
{
    my $self = shift;
    my $index = shift;

    __check_param($index);

    if (not exists $INDEX_of{$index})
    {
        OpenXPKI::Exception->throw (
            message => "I18N_OPENXPKI_SERVER_DBI_SCHEMA_GET_INDEX_TABLE_UNKNOWN_INDEX",
            params  => {
        INDEX => $index,
        });
    }

    return $INDEX_of{$index}->{TABLE};
}

sub get_index_columns
{
    my $self = shift;
    my $index = shift;

    __check_param($index);

    if (not exists $INDEX_of{$index})
    {
        OpenXPKI::Exception->throw (
            message => "I18N_OPENXPKI_SERVER_DBI_SCHEMA_GET_INDEX_COLUMNS_UNKNOWN_INDEX",
            params  => {
        INDEX => $index,
        });
    }

    return $INDEX_of{$index}->{COLUMNS};
}

########################################################################

sub set_namespace
{
    my $self = shift;
    my $namespace = shift;

    __check_param($namespace);

    $NAMESPACE = $namespace;
    return 1;
}

###########################################################################
# private methods.
# check if parameter is a valid SQL identifier:
# - defined
# - not empty string
# - only contains alphanumerics and underscores
# - caps only

sub __check_param {
    my $arg = shift;

    my $exception;

    # check if argument is specified
    if (! defined $arg || ($arg eq "")) {
    $exception = "NOT_SET";
    }

    # argument should be only alphanumeric
    if (! defined $exception &&
    ($arg !~ m{ \A \w+ \z }xms)) {
    $exception = "NOT_ALPHANUMERIC";
    }

    # argument should be upper case only
    if (! defined $exception &&
    ($arg ne uc($arg))) {
    $exception = "NOT_UPPERCASE_ONLY";
    }

    # NOTE: in order to add more checks here follow this pattern:
    #if (! defined $exception &&
    #    CONDITION) {
    #    $exception = "DESCRIPTION";
    #}

    # checks passed
    if (! defined $exception) {
    return 1;
    }

    # throw exception with caller information
    my ($package, $filename, $line, $subroutine, $hasargs,
    $wantarray, $evaltext, $is_require, $hints, $bitmask) = caller(1);

    OpenXPKI::Exception->throw (
    message => "I18N_OPENXPKI_SERVER_DBI_SCHEMA_CHECK_PARAMETER_" . $exception,
    params  => {
        PACKAGE => $package,
        CALLER  => $subroutine,
        PARAMETER => (defined $arg ? $arg : ""),
    },
    );
}

1;
__END__

=head1 Name

OpenXPKI::Server::DBI::Schema

=head1 Description

The major job of this class is to define and manage the schema
of the OpenXPKI database backend. This means that this class
has no real internal logic. It only implements several functions
to provide the other database classes with informations about
the database schema.

=head1 Database Schema

=head2 The CA table

The CA table is used to define a CA. Sounds simple? Yes, but it is a little
bit tricky. A certificate is identified via the primary key of the
certificate table. This primary key consists of the PKI realm, the name of
the issuing CA and the serial of the certificate. If such a certificate is
used as a CA certificate then we must associated this CA with a PKI realm
and we must give the CA a symbolic name.

If you want to interpret the table in a semantical manner then the table is
a connector which defines CAs inside of a PKI realm and connects certificates
with this CA. The same CA name is used by the token configuration.

=head2 GLOBAL_KEY_ID

The GLOBAL_KEY_ID is more or less a KEY_ID. It is used to identify all objects
which are related to one key. This is for example necessary to identify all
related objects if a revocation starts because of a key compromise. GLOBAL is
used to signal everybody that this ID is a GLOBAL unique ID.

=head1 Functions

=head2 Constructor

=head3 new

The constructor does not support any parameters.

=head2 Column informations

=head3 get_column

returns the native SQL column name for a given column name.

Example:  $schema->get_column ("CERTIFICATE_SERIAL");

=head2 Table informations

=head3 get_tables

returns all available table names (these are not the native SQL
table names).

=head3 get_table_name

returns the native SQL table name for a given table name.

=head3 get_table_index

returns an ARRAY reference to the columns which build the index of
the specified table.

=head3 get_table_columns

returns an ARRAY reference to the columns which are in
the specified table.

=head2 Sequence informations

=head3 get_sequences

returns all available sequence names (these are not the native SQL
sequence names).

=head3  get_sequence_name

returns the native SQL sequence name for a given sequence name.

=head2 Index informations

=head3 get_indexes

returns all available index names (these are not the native SQL
index names).

=head3  get_index_name

returns the native SQL index name for a given index name.

=head3 get_index_table

returns the table where an index is placed on.

=head3 get_index_columns

returns the columns which are used for an index.

=head2 Namespace handling

=head3 set_namespace

This is the only function where something is manipulated in the schema
during runtime. The namespace can be configured to seperate some users
inside the same database management system. The result is that all tables
are prefixed by the namespace.

=head2 Private methods

=head3 __check_param($)

Checks validity of specified argument as an SQL argument. This includes
checking if the argument is defined, not empty, alphanumeric and uppercase
only. Throws an exception if it isn't.

