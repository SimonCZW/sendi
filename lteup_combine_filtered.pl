#!/usr/bin/perl
#合并过滤完成文件并上传

use strict;
use Sys::Syslog;
use Net::FTP;
use POSIX qw(strftime);

#my $data_path = "/home/dpi";
my $output_path = "/home/dpi_filters";
#my $upload_path = "/home/dpidata";
#my $data_path = "/home/sendi_czw/hebin/test";
#my $output_path = "/home/sendi_czw/hebin";

#unless( -d $data_path )
#{
#        syslog('warning', "$data_path is not exists.");
#        exit;
#}
my @data_list;
@data_list = glob "/home/dpi_filter/home_dpi_LTEUP_HTTPWAP_20160406_totalfile_2016*";
@data_list = sort @data_list;
#剔除最后一个文件
splice(@data_list,-1);

my $count = 0;
my $total = 1;
my $total_file;

foreach my $data_file_do (@data_list)
        {
            $count = $count+1;
            #my $time = strftime("%Y%m%d%H%M%S", localtime);
            $total_file = "home_dpi_LTEUP_HTTPWAP_20160406"."_total_"."$total"; #replace_content: home_dpi_LTEUP_GAME_20160404
            if ( $count == 1 ){
                if ( $data_file_do =~ /(\d{14})/ ){
                         $start_tag = $1 ;
                }
                                                                                }
            `cat $data_file_do >> $output_path/$total_file`;
            `rm -f $data_file_do`;

            if ( $count == 20 or $data_file_do eq $data_list[-1] )
            {
                syslog('info' ,"finish combine $total_file.");
                if ( $data_file_do =~ /(\d{14})/ ){
                    $end_tag = $1 ;
                }
                #重命名
                my $rename = "home_dpi_LTEUP_HTTPWAP_20160406"."_${start_tag}"."_${end_tag}";
                `mv $output_path/$total_file $output_path/$rename` and syslog('warning', "Cannot rename $total_file.") or syslog('info', "rename $total_file to $rename.");
                #压缩上传
                system("/usr/bin/perl /home/sdnmuser/sendi_lteup_uploadfiles.pl $rename &") and syslog('warning', "Cannot compress and upload $rename.");
            }
        }
        else
        {
            $count = 0;
            $total = $total+1;
            redo;
        }
}
