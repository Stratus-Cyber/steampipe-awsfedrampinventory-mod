dashboard "FedRAMP-Inventory-Dashboard" {
	title = "FedRAMP Inventory Dashboard"


container {
  title = "Charts"
  width = 12
chart {
  type  = "bar"
  title = "Assets By OS"
  width = 6
    sql = <<-EOQ

WITH vpc_list as (
    SELECT DISTINCT
      vpc_id,
      title
    from
      aws_vpc
  ),
    all_ips as (
    select
	  attached_instance_id,
      network_interface_id,
      pvt_ip_addr -> 'Association' ->> 'PublicIp' as "IP",
      'Public' as "IP_Type"
    from
      aws_ec2_network_interface eni,
      jsonb_array_elements(eni.private_ip_addresses) as pvt_ip_addr
    where
      pvt_ip_addr -> 'Association' ->> 'PublicIp' is not null
    UNION ALL
    select
	  attached_instance_id,		
      network_interface_id,
      pvt_ip_addr ->> 'PrivateIpAddress' as "IP",
      'Private' as "IP_Type"
    from
      aws_ec2_network_interface eni,
      jsonb_array_elements(eni.private_ip_addresses) as pvt_ip_addr
    where
      pvt_ip_addr ->> 'PrivateIpAddress' is not null
	  and attached_instance_id is not null
  ),
  ami_list as (
    select
      image_id,
      name
    from
      aws_ec2_ami
  ),  
  network_interfaces as (
    SELECT
      file_system_id,
      jsonb_array_elements_text(network_interface_ids) "interface"
    FROM
      aws_fsx_file_system
  ),
  fsx_data as (
    SELECT
      --network_interfaces.interface,
      aws_fsx_file_system.title as "Unique Asset Identifier",
      jsonb_array_elements_text(network_interface_ids) "interface",
      --'' as "IPv4 or IPv6 Address",
      --	'' as "Public",
      dns_name as "DNS Name or URL",
      '' as "NetBIOS Name",
      '' as "MAC Address",
      tags ->> 'Authenticated_Scan' as "Authenticated Scan",
      tags ->> 'Baseline_Configuration_Name' as "Baseline Configuration Name",
      '' as "OS Name and Version",
      '' as "Location",
      'AWS ALB' as "Asset Type",
      '' as "Hardware Make/Model",
      '' as "In Latest Scan",
      '' as "Software/Database Vendor",
      '' as "Software/Database Name & Version",
      '' as "Patch Level",
      '' as "Diagram Label",
      tags ->> 'Comments' as "Comments",
      arn as "Serial #/Asset Tag#",
      CASE
        WHEN vpc_list.title is null THEN aws_fsx_file_system.vpc_id
        ELSE vpc_list.title
      END as "VLAN/Network ID",
      tags ->> 'Application_Owner' as "Application Owner",
      tags ->> 'System_Owner' as "System Owner",
      tags ->> 'Function' as "Function",
      '' as "End-of-Life"
    FROM
      aws_fsx_file_system
      INNER join vpc_list ON vpc_list.vpc_id = aws_fsx_file_system.vpc_id
  ),
  
  Full_Inventory as (
  --Application Load Balancer
  SELECT
	aws_ec2_application_load_balancer.title as "Unique Asset Identifier",
	'' as "IPv4 or IPv6 Address",
		'Yes' as "Virtual",
    tags ->> 'Public' as "Public",		
	--'' as "Public",
	dns_name as "DNS Name or URL",
	'' as "NetBIOS Name",
	'' as "MAC Address",
	tags ->> 'Authenticated_Scan' as "Authenticated Scan",
	tags ->> 'Baseline_Configuration_Name' as "Baseline Configuration Name",
	'' as "OS Name and Version",
	'' as "Location",
	'AWS ALB' as "Asset Type",
	'' as "Hardware Make/Model",
	'' as "In Latest Scan",
	'' as "Software/Database Vendor",
	'' as "Software/Database Name & Version",
	'' as "Patch Level",
	'' as "Diagram Label",
	tags ->> 'Comments' as "Comments",
	arn as "Serial #/Asset Tag#",
  CASE
    WHEN vpc_list.title is null THEN aws_ec2_application_load_balancer.vpc_id
    ELSE vpc_list.title
  END as "VLAN/Network ID",
	tags ->> 'Application_Owner' as "Application Owner",
	tags ->> 'System_Owner' as "System Owner",
	tags ->> 'Function' as "Function",
	'' as "End-of-Life"
FROM
	aws_ec2_application_load_balancer
	left join vpc_list ON vpc_list.vpc_id = aws_ec2_application_load_balancer.vpc_id
	
UNION

-- Classic Load Balancer
SELECT
	aws_ec2_classic_load_balancer.title as "Unique Asset Identifier",
	'' as "IPv4 or IPv6 Address",
	'Yes' as "Virtual",
	    tags ->> 'Public' as "Public",		

--CASE
--	WHEN scheme = 'internet-facing' THEN 'Yes'
--		ELSE 'No'
--	END as "Public",
	dns_name as "DNS Name or URL",
	'' as "NetBIOS Name",
	'' as "MAC Address",
	tags ->> 'Authenticated_Scan' as "Authenticated Scan",
	tags ->> 'Baseline_Configuration_Name' as "Baseline Configuration Name",
	'' as "OS Name and Version",
	'' as "Location",
	'AWS Load Balancer' as "Asset Type",
	'' as "Hardware Make/Model",
	'' as "In Latest Scan",
	'' as "Software/Database Vendor",
	'' as "Software/Database Name & Version",
	'' as "Patch Level",
	'' as "Diagram Label",
	tags ->> 'Comments' as "Comments",
	arn as "Serial #/Asset Tag#",
 CASE
    WHEN vpc_list.title is null THEN aws_ec2_classic_load_balancer.vpc_id
    ELSE vpc_list.title
 END as "VLAN/Network ID",
	tags ->> 'Application_Owner' as "Application Owner",
	tags ->> 'System_Owner' as "System Owner",
	tags ->> 'Function' as "Function",
	'' as "End-of-Life"
FROM
	aws_ec2_classic_load_balancer
	left join vpc_list ON vpc_list.vpc_id = aws_ec2_classic_load_balancer.vpc_id
	
	-- Directory Service	
	UNION
	
	SELECT
	aws_directory_service_directory.title as "Unique Asset Identifier",
	jsonb_array_elements_text(dns_ip_addrs) "IPv4 or IPv6 Address",
	'Yes' as "Virtual",
    tags ->> 'Public' as "Public",		
	--'' as "Public",
	access_url as "DNS Name or URL",
	directory_id as "NetBIOS Name",
	'' as "MAC Address",
	tags ->> 'Authenticated_Scan' as "Authenticated Scan",
	tags ->> 'Baseline_Configuration_Name' as "Baseline Configuration Name",
	'' as "OS Name and Version",
	region as "Location",
	'AWS Directory Service' as "Asset Type",
	'' as "Hardware Make/Model",
	'' as "In Latest Scan",
	type as "Software/Database Vendor",
	edition as "Software/Database Name & Version",
	'' as "Patch Level",
	'' as "Diagram Label",
	tags ->> 'Comments' as "Comments",
	arn as "Serial #/Asset Tag#",
  CASE
    WHEN vpc_list.title is null THEN vpc_settings ->> 'VpcId'
    ELSE vpc_list.title
  END as "VLAN/Network ID",
	tags ->> 'System_Owner' as "System Administrator/Owner",
	tags ->> 'Application_Owner' as "Application Administrator/Owner",
	tags ->> 'Function' as "Function",
	'' as "End-of-Life"
FROM
	aws_directory_service_directory
	left join vpc_list ON vpc_list.vpc_id = aws_directory_service_directory.vpc_settings ->> 'VpcId'
	
	-- EC2 Fedramp Inventory
	UNION
	
select
  instance_id as "Unique Asset Identifier",
    CASE
    WHEN "IP_Type" = 'Private' THEN "IP"
  END as "IPv4 or IPv6 Address",
  'Yes' as "Virtual",
      tags ->> 'Public' as "Public",		
  --CASE
    --WHEN "IP_Type" = 'Public' THEN "IP"
  --END as "Public",
  private_dns_name as "DNS Name or URL",
  aws_ec2_instance.title as "NetBIOS Name",
  '' as "MAC Address",
  tags ->> 'Authenticated_Scan' as "Authenticated Scan",
  tags ->> 'Baseline_Configuration_Name' as "Baseline Configuration Name",
  platform_details as "OS Name and Version",
  placement_availability_zone as "Location",
  'AWS EC2' as "Asset Type",
  instance_type as "Hardware Make/Model",
  '' as "In Latest Scan",
  CASE
    WHEN ami_list.name is null THEN aws_ec2_instance.image_id
    ELSE ami_list.name
  END as "Software/Database Vendor",
  '' as "Software/Database Name & Version",
  '' as "Patch Level",
  '' as "Diagram Label",
  tags ->> 'Comments' as "Comments",
  aws_ec2_instance.arn as "Serial #/Asset Tag#",
  vpc_list.title as "VLAN/Network ID",
  tags ->> 'Application_Owner' as "Application Owner",
  tags ->> 'System_Owner' as "System Owner",
  tags ->> 'Function' as "Function",
  '' as "End-of-Life"
from
  aws_ec2_instance
  left join all_ips ON all_ips.attached_instance_id = aws_ec2_instance.instance_id
  left join vpc_list ON vpc_list.vpc_id = aws_ec2_instance.vpc_id
  left join ami_list ON ami_list.image_id = aws_ec2_instance.image_id
where
  instance_state = 'running'
	
	-- FSX File System
	UNION
	
	SELECT
  "Unique Asset Identifier",
  CASE
    WHEN all_ips."IP_Type" = 'Private' THEN "IP"
  END as "IPv4 or IPv6 Address",
  	'Yes' as "Virtual",
	'' as "Public",
  --CASE
    --WHEN all_ips."IP_Type" = 'Public' THEN all_ips."IP"
  --END as "Public",
  "DNS Name or URL",
  '' as "NetBIOS Name",
  '' as "MAC Address",
  "Authenticated Scan",
  "Baseline Configuration Name",
  '' as "OS Name and Version",
  '' as "Location",
  'AWS ALB' as "Asset Type",
  '' as "Hardware Make/Model",
  '' as "In Latest Scan",
  '' as "Software/Database Vendor",
  '' as "Software/Database Name & Version",
  '' as "Patch Level",
  '' as "Diagram Label",
  "Comments",
  '' as "Serial #/Asset Tag#",
  "VLAN/Network ID",
  "Application Owner",
  "System Owner",
  "Function",
  "End-of-Life"
FROM
  fsx_data
  inner join all_ips ON all_ips.network_interface_id = fsx_data.interface
  
  
  --Internet Gateway
UNION

 SELECT
	aws_vpc_internet_gateway.title as "Unique Asset Identifier",
	'' as "IPv4 or IPv6 Address",
	'Yes' as "Virtual",
    tags ->> 'Public' as "Public",		
	--'' as "Public",
	'' as "DNS Name or URL",
	internet_gateway_id as "NetBIOS Name",
	'' as "MAC Address",
	tags ->> 'Authenticated_Scan' as "Authenticated Scan",
	tags ->> 'Baseline_Configuration_Name' as "Baseline Configuration Name",
	'' as "OS Name and Version",
	region as "Location",
	'AWS Internet Gateway' as "Asset Type",
	'' as "Hardware Make/Model",
	'' as "In Latest Scan",
	'' as "Software/Database Vendor",
	'' as "Software/Database Name & Version",
	'' as "Patch Level",
	'' as "Diagram Label",
	tags ->> 'Comments' as "Comments",
	jsonb_array_elements_text(akas) as "Serial #/Asset Tag#", 
	CASE
		WHEN vpc_list.title is null THEN aws_vpc_internet_gateway.attachments -> 0 ->> 'VpcId'
		ELSE vpc_list.title
	END as "VLAN/Network ID",
	tags ->> 'Application_Owner' as "Application Owner",
	tags ->> 'System_Owner' as "System Owner",
	tags ->> 'Function' as "Function",
	'' as "End-of-Life"
FROM
	aws_vpc_internet_gateway
	left join vpc_list ON vpc_list.vpc_id = aws_vpc_internet_gateway.attachments -> 0 ->> 'VpcId'
	
	--Network Load Balancer
	
	UNION
	
SELECT
	aws_ec2_network_load_balancer.title as "Unique Asset Identifier",
	'' as "IPv4 or IPv6 Address",
	'Yes' as "Virtual",
    tags ->> 'Public' as "Public",		
	--'' as "Public",
	dns_name as "DNS Name or URL",
	'' as "NetBIOS Name",
	'' as "MAC Address",
	tags ->> 'Authenticated_Scan' as "Authenticated Scan",
	tags ->> 'Baseline_Configuration_Name' as "Baseline Configuration Name",
	'' as "OS Name and Version",
	region as "Location",
	'AWS NLB' as "Asset Type",
	'' as "Hardware Make/Model",
	'' as "In Latest Scan",
	'' as "Software/Database Vendor",
	'' as "Software/Database Name & Version",
	'' as "Patch Level",
	'' as "Diagram Label",
	tags ->> 'Comments' as "Comments",
	jsonb_array_elements_text(akas) as "Serial #/Asset Tag#",
	CASE
		WHEN vpc_list.title is null THEN aws_ec2_network_load_balancer.vpc_id
		ELSE vpc_list.title
	END as "VLAN/Network ID",
	tags ->> 'Application_Owner' as "Application Owner",
	tags ->> 'System_Owner' as "System Owner",
	tags ->> 'Function' as "Function",
	'' as "End-of-Life"
FROM
	aws_ec2_network_load_balancer
	left join vpc_list ON vpc_list.vpc_id = aws_ec2_network_load_balancer.vpc_id
	
	-- Open Search
	
	UNION
	
	  SELECT
	aws_opensearch_domain.title as "Unique Asset Identifier",
	'' as "IPv4 or IPv6 Address",
	  	'Yes' as "Virtual",
    tags ->> 'Public' as "Public",		
	--'' as "Public",
	--dns_name as "DNS Name or URL",
	'' as "DNS Name or URL",
	'' as "NetBIOS Name",
	'' as "MAC Address",
	tags ->> 'Authenticated_Scan' as "Authenticated Scan",
	tags ->> 'Baseline_Configuration_Name' as "Baseline Configuration Name",
	'' as "OS Name and Version",
	'' as "Location",
	'AWS ALB' as "Asset Type",
	'' as "Hardware Make/Model",
	'' as "In Latest Scan",
	'' as "Software/Database Vendor",
	'' as "Software/Database Name & Version",
	'' as "Patch Level",
	'' as "Diagram Label",
	tags ->> 'Comments' as "Comments",
	arn as "Serial #/Asset Tag#",
  CASE
    WHEN vpc_list.title is null THEN aws_opensearch_domain.vpc_options ->> 'VPCId'
    ELSE vpc_list.title
  END as "VLAN/Network ID",
	tags ->> 'Application_Owner' as "Application Owner",
	tags ->> 'System_Owner' as "System Owner",
	tags ->> 'Function' as "Function",
	'' as "End-of-Life"
FROM
	aws_opensearch_domain
	left join vpc_list ON vpc_list.vpc_id = aws_opensearch_domain.vpc_options ->> 'VPCId'
	
	-- RDS Fedramp inventory
	
	UNION
SELECT
	text(db_instance_identifier) as "Unique Asset Identifier",
	'' as "IPv4 or IPv6 Address",
	'Yes' as "Virtual",
    tags ->> 'Public' as "Public",			
	--'publicly_accessible' as "Public",
	endpoint_address || ':' || endpoint_port as "DNS Name or URL",
	resource_id as "NetBIOS Name",
	'' as "MAC Address",
	tags ->> 'Authenticated_Scan' as "Authenticated Scan",
	tags ->> 'Baseline_Configuration_Name' as "Baseline Configuration Name",
	'' as "OS Name and Version",
	availability_zone as "Location",
	'AWS RDS' as "Asset Type",
	class as "Hardware Make/Model",
	'' as "In Latest Scan",
	engine as "Software/Database Vendor",
	engine_version as "Software/Database Name & Version",
	'' as "Patch Level",
	'' as "Diagram Label",
	tags ->> 'Comments' as "Comments",
	arn as "Serial #/Asset Tag#",
	db_subnet_group_name as "VLAN/Network ID",
	tags ->> 'Application_Owner' as "Application Owner",
	tags ->> 'System_Owner' as "System Owner",
	tags ->> 'Function' as "Function",
	'' as "End-of-Life"
FROM
	aws_rds_db_instance	
	
	-- S3 bucket inventory
	UNION
SELECT
	title as "Unique Asset Identifier",
	'' as "IPv4 or IPv6 Address",
	'Yes' as "Virtual",
    tags ->> 'Public' as "Public",		
	--'' as "Public",
	'' as "DNS Name or URL",
	'' as "NetBIOS Name",
	'' as "MAC Address",
	tags ->> 'Authenticated_Scan' as "Authenticated Scan",
	tags ->> 'Baseline_Configuration_Name' as "Baseline Configuration Name",
	'' as "OS Name and Version",
	region as "Location",
	'AWS S3' as "Asset Type",
	'' as "Hardware Make/Model",
	'' as "In Latest Scan",
	'' as "Software/Database Vendor",
	'' as "Software/Database Name & Version",
	'' as "Patch Level",
	'' as "Diagram Label",
	tags ->> 'Comments' as "Comments",
	arn as "Serial #/Asset Tag#",
	'' as "VLAN/Network ID",
	tags ->> 'Application_Owner' as "Application Owner",
	tags ->> 'System_Owner' as "System Owner",
	tags ->> 'Function' as "Function",
	'' as "End-of-Life"
FROM
	aws_s3_bucket	
	
-- Subnet VPC Inventory

UNION
SELECT
	aws_vpc_subnet.title as "Unique Asset Identifier",
	text(cidr_block) as "IPv4 or IPv6 Address",
	'Yes' as "Virtual",
    tags ->> 'Public' as "Public",		
	--'' as "Public",
	'' as "DNS Name or URL",
	subnet_id as "NetBIOS Name",
	'' as "MAC Address",
	tags ->> 'Authenticated_Scan' as "Authenticated Scan",
	tags ->> 'Baseline_Configuration_Name' as "Baseline Configuration Name",
	'' as "OS Name and Version",
	availability_zone as "Location",
	'AWS VPC Subnet' as "Asset Type",
	'' as "Hardware Make/Model",
	'' as "In Latest Scan",
	'' as "Software/Database Vendor",
	'' as "Software/Database Name & Version",
	'' as "Patch Level",
	'' as "Diagram Label",
	tags ->> 'Comments' as "Comments",
	subnet_arn as "Serial #/Asset Tag#",
 CASE
    WHEN vpc_list.title is null THEN aws_vpc_subnet.vpc_id
    ELSE vpc_list.title
 END as "VLAN/Network ID",
	tags ->> 'Application_Owner' as "Application Owner",
	tags ->> 'System_Owner' as "System Owner",
	tags ->> 'Function' as "Function",
	'' as "End-of-Life"
FROM
	aws_vpc_subnet
	left join vpc_list ON vpc_list.vpc_id = aws_vpc_subnet.vpc_id
	
	-- VPC Nat Gateway Inventory
	
UNION

SELECT
	aws_vpc_nat_gateway.title as "Unique Asset Identifier",
	'' as "IPv4 or IPv6 Address",
	'Yes' as "Virtual",
    tags ->> 'Public' as "Public",		
	--'' as "Public",
	'' as "DNS Name or URL",
	nat_gateway_id as "NetBIOS Name",
	'' as "MAC Address",
	tags ->> 'Authenticated_Scan' as "Authenticated Scan",
	tags ->> 'Baseline_Configuration_Name' as "Baseline Configuration Name",
	'' as "OS Name and Version",
	region as "Location",
	'AWS VPC NAT Gateway' as "Asset Type",
	'' as "Hardware Make/Model",
	'' as "In Latest Scan",
	'' as "Software/Database Vendor",
	'' as "Software/Database Name & Version",
	'' as "Patch Level",
	'' as "Diagram Label",
	tags ->> 'Comments' as "Comments",
	arn as "Serial #/Asset Tag#",
 CASE
    WHEN vpc_list.title is null THEN aws_vpc_nat_gateway.vpc_id
    ELSE vpc_list.title
 END as "VLAN/Network ID",
	tags ->> 'Application_Owner' as "Application Owner",
	tags ->> 'System_Owner' as "System Owner",
	tags ->> 'Function' as "Function",
	'' as "End-of-Life"
FROM
	aws_vpc_nat_gateway
	left join vpc_list ON vpc_list.vpc_id = aws_vpc_nat_gateway.vpc_id
)
	
SELECT "OS Name and Version", COUNT(DISTINCT "Unique Asset Identifier") AS "Inventory Count"
FROM Full_Inventory
WHERE "Asset Type" = 'AWS EC2'
AND "OS Name and Version" is not null
GROUP BY "OS Name and Version"
ORDER BY "Inventory Count" DESC


  EOQ
}

chart {
  type  = "bar"
  title = "Unique Assets By Type"
  width = 6
    sql = <<-EOQ

WITH vpc_list as (
    SELECT DISTINCT
      vpc_id,
      title
    from
      aws_vpc
  ),
    all_ips as (
    select
	  attached_instance_id,
      network_interface_id,
      pvt_ip_addr -> 'Association' ->> 'PublicIp' as "IP",
      'Public' as "IP_Type"
    from
      aws_ec2_network_interface eni,
      jsonb_array_elements(eni.private_ip_addresses) as pvt_ip_addr
    where
      pvt_ip_addr -> 'Association' ->> 'PublicIp' is not null
    UNION ALL
    select
	  attached_instance_id,		
      network_interface_id,
      pvt_ip_addr ->> 'PrivateIpAddress' as "IP",
      'Private' as "IP_Type"
    from
      aws_ec2_network_interface eni,
      jsonb_array_elements(eni.private_ip_addresses) as pvt_ip_addr
    where
      pvt_ip_addr ->> 'PrivateIpAddress' is not null
	  and attached_instance_id is not null
  ),
  ami_list as (
    select
      image_id,
      name
    from
      aws_ec2_ami
  ),  
  network_interfaces as (
    SELECT
      file_system_id,
      jsonb_array_elements_text(network_interface_ids) "interface"
    FROM
      aws_fsx_file_system
  ),
  fsx_data as (
    SELECT
      --network_interfaces.interface,
      aws_fsx_file_system.title as "Unique Asset Identifier",
      jsonb_array_elements_text(network_interface_ids) "interface",
      --'' as "IPv4 or IPv6 Address",
      --	'' as "Public",
      dns_name as "DNS Name or URL",
      '' as "NetBIOS Name",
      '' as "MAC Address",
      tags ->> 'Authenticated_Scan' as "Authenticated Scan",
      tags ->> 'Baseline_Configuration_Name' as "Baseline Configuration Name",
      '' as "OS Name and Version",
      '' as "Location",
      'AWS ALB' as "Asset Type",
      '' as "Hardware Make/Model",
      '' as "In Latest Scan",
      '' as "Software/Database Vendor",
      '' as "Software/Database Name & Version",
      '' as "Patch Level",
      '' as "Diagram Label",
      tags ->> 'Comments' as "Comments",
      arn as "Serial #/Asset Tag#",
      CASE
        WHEN vpc_list.title is null THEN aws_fsx_file_system.vpc_id
        ELSE vpc_list.title
      END as "VLAN/Network ID",
      tags ->> 'Application_Owner' as "Application Owner",
      tags ->> 'System_Owner' as "System Owner",
      tags ->> 'Function' as "Function",
      '' as "End-of-Life"
    FROM
      aws_fsx_file_system
      INNER join vpc_list ON vpc_list.vpc_id = aws_fsx_file_system.vpc_id
  ),
  
  Full_Inventory as (
  --Application Load Balancer
  SELECT
	aws_ec2_application_load_balancer.title as "Unique Asset Identifier",
	'' as "IPv4 or IPv6 Address",
		'Yes' as "Virtual",
    tags ->> 'Public' as "Public",		
	--'' as "Public",
	dns_name as "DNS Name or URL",
	'' as "NetBIOS Name",
	'' as "MAC Address",
	tags ->> 'Authenticated_Scan' as "Authenticated Scan",
	tags ->> 'Baseline_Configuration_Name' as "Baseline Configuration Name",
	'' as "OS Name and Version",
	'' as "Location",
	'AWS ALB' as "Asset Type",
	'' as "Hardware Make/Model",
	'' as "In Latest Scan",
	'' as "Software/Database Vendor",
	'' as "Software/Database Name & Version",
	'' as "Patch Level",
	'' as "Diagram Label",
	tags ->> 'Comments' as "Comments",
	arn as "Serial #/Asset Tag#",
  CASE
    WHEN vpc_list.title is null THEN aws_ec2_application_load_balancer.vpc_id
    ELSE vpc_list.title
  END as "VLAN/Network ID",
	tags ->> 'Application_Owner' as "Application Owner",
	tags ->> 'System_Owner' as "System Owner",
	tags ->> 'Function' as "Function",
	'' as "End-of-Life"
FROM
	aws_ec2_application_load_balancer
	left join vpc_list ON vpc_list.vpc_id = aws_ec2_application_load_balancer.vpc_id
	
UNION

-- Classic Load Balancer
SELECT
	aws_ec2_classic_load_balancer.title as "Unique Asset Identifier",
	'' as "IPv4 or IPv6 Address",
	'Yes' as "Virtual",
	    tags ->> 'Public' as "Public",		

--CASE
--	WHEN scheme = 'internet-facing' THEN 'Yes'
--		ELSE 'No'
--	END as "Public",
	dns_name as "DNS Name or URL",
	'' as "NetBIOS Name",
	'' as "MAC Address",
	tags ->> 'Authenticated_Scan' as "Authenticated Scan",
	tags ->> 'Baseline_Configuration_Name' as "Baseline Configuration Name",
	'' as "OS Name and Version",
	'' as "Location",
	'AWS Load Balancer' as "Asset Type",
	'' as "Hardware Make/Model",
	'' as "In Latest Scan",
	'' as "Software/Database Vendor",
	'' as "Software/Database Name & Version",
	'' as "Patch Level",
	'' as "Diagram Label",
	tags ->> 'Comments' as "Comments",
	arn as "Serial #/Asset Tag#",
 CASE
    WHEN vpc_list.title is null THEN aws_ec2_classic_load_balancer.vpc_id
    ELSE vpc_list.title
 END as "VLAN/Network ID",
	tags ->> 'Application_Owner' as "Application Owner",
	tags ->> 'System_Owner' as "System Owner",
	tags ->> 'Function' as "Function",
	'' as "End-of-Life"
FROM
	aws_ec2_classic_load_balancer
	left join vpc_list ON vpc_list.vpc_id = aws_ec2_classic_load_balancer.vpc_id
	
	-- Directory Service	
	UNION
	
	SELECT
	aws_directory_service_directory.title as "Unique Asset Identifier",
	jsonb_array_elements_text(dns_ip_addrs) "IPv4 or IPv6 Address",
	'Yes' as "Virtual",
    tags ->> 'Public' as "Public",		
	--'' as "Public",
	access_url as "DNS Name or URL",
	directory_id as "NetBIOS Name",
	'' as "MAC Address",
	tags ->> 'Authenticated_Scan' as "Authenticated Scan",
	tags ->> 'Baseline_Configuration_Name' as "Baseline Configuration Name",
	'' as "OS Name and Version",
	region as "Location",
	'AWS Directory Service' as "Asset Type",
	'' as "Hardware Make/Model",
	'' as "In Latest Scan",
	type as "Software/Database Vendor",
	edition as "Software/Database Name & Version",
	'' as "Patch Level",
	'' as "Diagram Label",
	tags ->> 'Comments' as "Comments",
	arn as "Serial #/Asset Tag#",
  CASE
    WHEN vpc_list.title is null THEN vpc_settings ->> 'VpcId'
    ELSE vpc_list.title
  END as "VLAN/Network ID",
	tags ->> 'System_Owner' as "System Administrator/Owner",
	tags ->> 'Application_Owner' as "Application Administrator/Owner",
	tags ->> 'Function' as "Function",
	'' as "End-of-Life"
FROM
	aws_directory_service_directory
	left join vpc_list ON vpc_list.vpc_id = aws_directory_service_directory.vpc_settings ->> 'VpcId'
	
	-- EC2 Fedramp Inventory
	UNION
	
select
  instance_id as "Unique Asset Identifier",
    CASE
    WHEN "IP_Type" = 'Private' THEN "IP"
  END as "IPv4 or IPv6 Address",
  'Yes' as "Virtual",
      tags ->> 'Public' as "Public",		
  --CASE
    --WHEN "IP_Type" = 'Public' THEN "IP"
  --END as "Public",
  private_dns_name as "DNS Name or URL",
  aws_ec2_instance.title as "NetBIOS Name",
  '' as "MAC Address",
  tags ->> 'Authenticated_Scan' as "Authenticated Scan",
  tags ->> 'Baseline_Configuration_Name' as "Baseline Configuration Name",
  platform_details as "OS Name and Version",
  placement_availability_zone as "Location",
  'AWS EC2' as "Asset Type",
  instance_type as "Hardware Make/Model",
  '' as "In Latest Scan",
  CASE
    WHEN ami_list.name is null THEN aws_ec2_instance.image_id
    ELSE ami_list.name
  END as "Software/Database Vendor",
  '' as "Software/Database Name & Version",
  '' as "Patch Level",
  '' as "Diagram Label",
  tags ->> 'Comments' as "Comments",
  aws_ec2_instance.arn as "Serial #/Asset Tag#",
  vpc_list.title as "VLAN/Network ID",
  tags ->> 'Application_Owner' as "Application Owner",
  tags ->> 'System_Owner' as "System Owner",
  tags ->> 'Function' as "Function",
  '' as "End-of-Life"
from
  aws_ec2_instance
  left join all_ips ON all_ips.attached_instance_id = aws_ec2_instance.instance_id
  left join vpc_list ON vpc_list.vpc_id = aws_ec2_instance.vpc_id
  left join ami_list ON ami_list.image_id = aws_ec2_instance.image_id
where
  instance_state = 'running'
	
	-- FSX File System
	UNION
	
	SELECT
  "Unique Asset Identifier",
  CASE
    WHEN all_ips."IP_Type" = 'Private' THEN "IP"
  END as "IPv4 or IPv6 Address",
  	'Yes' as "Virtual",
	'' as "Public",
  --CASE
    --WHEN all_ips."IP_Type" = 'Public' THEN all_ips."IP"
  --END as "Public",
  "DNS Name or URL",
  '' as "NetBIOS Name",
  '' as "MAC Address",
  "Authenticated Scan",
  "Baseline Configuration Name",
  '' as "OS Name and Version",
  '' as "Location",
  'AWS ALB' as "Asset Type",
  '' as "Hardware Make/Model",
  '' as "In Latest Scan",
  '' as "Software/Database Vendor",
  '' as "Software/Database Name & Version",
  '' as "Patch Level",
  '' as "Diagram Label",
  "Comments",
  '' as "Serial #/Asset Tag#",
  "VLAN/Network ID",
  "Application Owner",
  "System Owner",
  "Function",
  "End-of-Life"
FROM
  fsx_data
  inner join all_ips ON all_ips.network_interface_id = fsx_data.interface
  
  
  --Internet Gateway
UNION

 SELECT
	aws_vpc_internet_gateway.title as "Unique Asset Identifier",
	'' as "IPv4 or IPv6 Address",
	'Yes' as "Virtual",
    tags ->> 'Public' as "Public",		
	--'' as "Public",
	'' as "DNS Name or URL",
	internet_gateway_id as "NetBIOS Name",
	'' as "MAC Address",
	tags ->> 'Authenticated_Scan' as "Authenticated Scan",
	tags ->> 'Baseline_Configuration_Name' as "Baseline Configuration Name",
	'' as "OS Name and Version",
	region as "Location",
	'AWS Internet Gateway' as "Asset Type",
	'' as "Hardware Make/Model",
	'' as "In Latest Scan",
	'' as "Software/Database Vendor",
	'' as "Software/Database Name & Version",
	'' as "Patch Level",
	'' as "Diagram Label",
	tags ->> 'Comments' as "Comments",
	jsonb_array_elements_text(akas) as "Serial #/Asset Tag#", 
	CASE
		WHEN vpc_list.title is null THEN aws_vpc_internet_gateway.attachments -> 0 ->> 'VpcId'
		ELSE vpc_list.title
	END as "VLAN/Network ID",
	tags ->> 'Application_Owner' as "Application Owner",
	tags ->> 'System_Owner' as "System Owner",
	tags ->> 'Function' as "Function",
	'' as "End-of-Life"
FROM
	aws_vpc_internet_gateway
	left join vpc_list ON vpc_list.vpc_id = aws_vpc_internet_gateway.attachments -> 0 ->> 'VpcId'
	
	--Network Load Balancer
	
	UNION
	
SELECT
	aws_ec2_network_load_balancer.title as "Unique Asset Identifier",
	'' as "IPv4 or IPv6 Address",
	'Yes' as "Virtual",
    tags ->> 'Public' as "Public",		
	--'' as "Public",
	dns_name as "DNS Name or URL",
	'' as "NetBIOS Name",
	'' as "MAC Address",
	tags ->> 'Authenticated_Scan' as "Authenticated Scan",
	tags ->> 'Baseline_Configuration_Name' as "Baseline Configuration Name",
	'' as "OS Name and Version",
	region as "Location",
	'AWS NLB' as "Asset Type",
	'' as "Hardware Make/Model",
	'' as "In Latest Scan",
	'' as "Software/Database Vendor",
	'' as "Software/Database Name & Version",
	'' as "Patch Level",
	'' as "Diagram Label",
	tags ->> 'Comments' as "Comments",
	jsonb_array_elements_text(akas) as "Serial #/Asset Tag#",
	CASE
		WHEN vpc_list.title is null THEN aws_ec2_network_load_balancer.vpc_id
		ELSE vpc_list.title
	END as "VLAN/Network ID",
	tags ->> 'Application_Owner' as "Application Owner",
	tags ->> 'System_Owner' as "System Owner",
	tags ->> 'Function' as "Function",
	'' as "End-of-Life"
FROM
	aws_ec2_network_load_balancer
	left join vpc_list ON vpc_list.vpc_id = aws_ec2_network_load_balancer.vpc_id
	
	-- Open Search
	
	UNION
	
	  SELECT
	aws_opensearch_domain.title as "Unique Asset Identifier",
	'' as "IPv4 or IPv6 Address",
	  	'Yes' as "Virtual",
    tags ->> 'Public' as "Public",		
	--'' as "Public",
	--dns_name as "DNS Name or URL",
	'' as "DNS Name or URL",
	'' as "NetBIOS Name",
	'' as "MAC Address",
	tags ->> 'Authenticated_Scan' as "Authenticated Scan",
	tags ->> 'Baseline_Configuration_Name' as "Baseline Configuration Name",
	'' as "OS Name and Version",
	'' as "Location",
	'AWS ALB' as "Asset Type",
	'' as "Hardware Make/Model",
	'' as "In Latest Scan",
	'' as "Software/Database Vendor",
	'' as "Software/Database Name & Version",
	'' as "Patch Level",
	'' as "Diagram Label",
	tags ->> 'Comments' as "Comments",
	arn as "Serial #/Asset Tag#",
  CASE
    WHEN vpc_list.title is null THEN aws_opensearch_domain.vpc_options ->> 'VPCId'
    ELSE vpc_list.title
  END as "VLAN/Network ID",
	tags ->> 'Application_Owner' as "Application Owner",
	tags ->> 'System_Owner' as "System Owner",
	tags ->> 'Function' as "Function",
	'' as "End-of-Life"
FROM
	aws_opensearch_domain
	left join vpc_list ON vpc_list.vpc_id = aws_opensearch_domain.vpc_options ->> 'VPCId'
	
	-- RDS Fedramp inventory
	
	UNION
SELECT
	text(db_instance_identifier) as "Unique Asset Identifier",
	'' as "IPv4 or IPv6 Address",
	'Yes' as "Virtual",
    tags ->> 'Public' as "Public",			
	--'publicly_accessible' as "Public",
	endpoint_address || ':' || endpoint_port as "DNS Name or URL",
	resource_id as "NetBIOS Name",
	'' as "MAC Address",
	tags ->> 'Authenticated_Scan' as "Authenticated Scan",
	tags ->> 'Baseline_Configuration_Name' as "Baseline Configuration Name",
	'' as "OS Name and Version",
	availability_zone as "Location",
	'AWS RDS' as "Asset Type",
	class as "Hardware Make/Model",
	'' as "In Latest Scan",
	engine as "Software/Database Vendor",
	engine_version as "Software/Database Name & Version",
	'' as "Patch Level",
	'' as "Diagram Label",
	tags ->> 'Comments' as "Comments",
	arn as "Serial #/Asset Tag#",
	db_subnet_group_name as "VLAN/Network ID",
	tags ->> 'Application_Owner' as "Application Owner",
	tags ->> 'System_Owner' as "System Owner",
	tags ->> 'Function' as "Function",
	'' as "End-of-Life"
FROM
	aws_rds_db_instance	
	
	-- S3 bucket inventory
	UNION
SELECT
	title as "Unique Asset Identifier",
	'' as "IPv4 or IPv6 Address",
	'Yes' as "Virtual",
    tags ->> 'Public' as "Public",		
	--'' as "Public",
	'' as "DNS Name or URL",
	'' as "NetBIOS Name",
	'' as "MAC Address",
	tags ->> 'Authenticated_Scan' as "Authenticated Scan",
	tags ->> 'Baseline_Configuration_Name' as "Baseline Configuration Name",
	'' as "OS Name and Version",
	region as "Location",
	'AWS S3' as "Asset Type",
	'' as "Hardware Make/Model",
	'' as "In Latest Scan",
	'' as "Software/Database Vendor",
	'' as "Software/Database Name & Version",
	'' as "Patch Level",
	'' as "Diagram Label",
	tags ->> 'Comments' as "Comments",
	arn as "Serial #/Asset Tag#",
	'' as "VLAN/Network ID",
	tags ->> 'Application_Owner' as "Application Owner",
	tags ->> 'System_Owner' as "System Owner",
	tags ->> 'Function' as "Function",
	'' as "End-of-Life"
FROM
	aws_s3_bucket	
	
-- Subnet VPC Inventory

UNION
SELECT
	aws_vpc_subnet.title as "Unique Asset Identifier",
	text(cidr_block) as "IPv4 or IPv6 Address",
	'Yes' as "Virtual",
    tags ->> 'Public' as "Public",		
	--'' as "Public",
	'' as "DNS Name or URL",
	subnet_id as "NetBIOS Name",
	'' as "MAC Address",
	tags ->> 'Authenticated_Scan' as "Authenticated Scan",
	tags ->> 'Baseline_Configuration_Name' as "Baseline Configuration Name",
	'' as "OS Name and Version",
	availability_zone as "Location",
	'AWS VPC Subnet' as "Asset Type",
	'' as "Hardware Make/Model",
	'' as "In Latest Scan",
	'' as "Software/Database Vendor",
	'' as "Software/Database Name & Version",
	'' as "Patch Level",
	'' as "Diagram Label",
	tags ->> 'Comments' as "Comments",
	subnet_arn as "Serial #/Asset Tag#",
 CASE
    WHEN vpc_list.title is null THEN aws_vpc_subnet.vpc_id
    ELSE vpc_list.title
 END as "VLAN/Network ID",
	tags ->> 'Application_Owner' as "Application Owner",
	tags ->> 'System_Owner' as "System Owner",
	tags ->> 'Function' as "Function",
	'' as "End-of-Life"
FROM
	aws_vpc_subnet
	left join vpc_list ON vpc_list.vpc_id = aws_vpc_subnet.vpc_id
	
	-- VPC Nat Gateway Inventory
	
UNION

SELECT
	aws_vpc_nat_gateway.title as "Unique Asset Identifier",
	'' as "IPv4 or IPv6 Address",
	'Yes' as "Virtual",
    tags ->> 'Public' as "Public",		
	--'' as "Public",
	'' as "DNS Name or URL",
	nat_gateway_id as "NetBIOS Name",
	'' as "MAC Address",
	tags ->> 'Authenticated_Scan' as "Authenticated Scan",
	tags ->> 'Baseline_Configuration_Name' as "Baseline Configuration Name",
	'' as "OS Name and Version",
	region as "Location",
	'AWS VPC NAT Gateway' as "Asset Type",
	'' as "Hardware Make/Model",
	'' as "In Latest Scan",
	'' as "Software/Database Vendor",
	'' as "Software/Database Name & Version",
	'' as "Patch Level",
	'' as "Diagram Label",
	tags ->> 'Comments' as "Comments",
	arn as "Serial #/Asset Tag#",
 CASE
    WHEN vpc_list.title is null THEN aws_vpc_nat_gateway.vpc_id
    ELSE vpc_list.title
 END as "VLAN/Network ID",
	tags ->> 'Application_Owner' as "Application Owner",
	tags ->> 'System_Owner' as "System Owner",
	tags ->> 'Function' as "Function",
	'' as "End-of-Life"
FROM
	aws_vpc_nat_gateway
	left join vpc_list ON vpc_list.vpc_id = aws_vpc_nat_gateway.vpc_id
)
	
SELECT "Asset Type", COUNT(DISTINCT "Unique Asset Identifier") AS "Inventory Count"
FROM Full_Inventory
GROUP BY "Asset Type"
ORDER BY "Inventory Count" DESC;


  EOQ
}
}  

card {
  sql = <<-EOQ
WITH vpc_list as (
    SELECT DISTINCT
      vpc_id,
      title
    from
      aws_vpc
  ),
    all_ips as (
    select
	  attached_instance_id,
      network_interface_id,
      pvt_ip_addr -> 'Association' ->> 'PublicIp' as "IP",
      'Public' as "IP_Type"
    from
      aws_ec2_network_interface eni,
      jsonb_array_elements(eni.private_ip_addresses) as pvt_ip_addr
    where
      pvt_ip_addr -> 'Association' ->> 'PublicIp' is not null
    UNION ALL
    select
	  attached_instance_id,		
      network_interface_id,
      pvt_ip_addr ->> 'PrivateIpAddress' as "IP",
      'Private' as "IP_Type"
    from
      aws_ec2_network_interface eni,
      jsonb_array_elements(eni.private_ip_addresses) as pvt_ip_addr
    where
      pvt_ip_addr ->> 'PrivateIpAddress' is not null
	  and attached_instance_id is not null
  ),
  ami_list as (
    select
      image_id,
      name
    from
      aws_ec2_ami
  ),  
  network_interfaces as (
    SELECT
      file_system_id,
      jsonb_array_elements_text(network_interface_ids) "interface"
    FROM
      aws_fsx_file_system
  ),
  fsx_data as (
    SELECT
      --network_interfaces.interface,
      aws_fsx_file_system.title as "Unique Asset Identifier",
      jsonb_array_elements_text(network_interface_ids) "interface",
      --'' as "IPv4 or IPv6 Address",
      --	'' as "Public",
      dns_name as "DNS Name or URL",
      '' as "NetBIOS Name",
      '' as "MAC Address",
      tags ->> 'Authenticated_Scan' as "Authenticated Scan",
      tags ->> 'Baseline_Configuration_Name' as "Baseline Configuration Name",
      '' as "OS Name and Version",
      '' as "Location",
      'AWS ALB' as "Asset Type",
      '' as "Hardware Make/Model",
      '' as "In Latest Scan",
      '' as "Software/Database Vendor",
      '' as "Software/Database Name & Version",
      '' as "Patch Level",
      '' as "Diagram Label",
      tags ->> 'Comments' as "Comments",
      arn as "Serial #/Asset Tag#",
      CASE
        WHEN vpc_list.title is null THEN aws_fsx_file_system.vpc_id
        ELSE vpc_list.title
      END as "VLAN/Network ID",
      tags ->> 'Application_Owner' as "Application Owner",
      tags ->> 'System_Owner' as "System Owner",
      tags ->> 'Function' as "Function",
      '' as "End-of-Life"
    FROM
      aws_fsx_file_system
      INNER join vpc_list ON vpc_list.vpc_id = aws_fsx_file_system.vpc_id
  )
  
  --Application Load Balancer
  SELECT
	aws_ec2_application_load_balancer.title as "Unique Asset Identifier",
	'' as "IPv4 or IPv6 Address",
		'Yes' as "Virtual",
    tags ->> 'Public' as "Public",		
	--'' as "Public",
	dns_name as "DNS Name or URL",
	'' as "NetBIOS Name",
	'' as "MAC Address",
	tags ->> 'Authenticated_Scan' as "Authenticated Scan",
	tags ->> 'Baseline_Configuration_Name' as "Baseline Configuration Name",
	'' as "OS Name and Version",
	'' as "Location",
	'AWS ALB' as "Asset Type",
	'' as "Hardware Make/Model",
	'' as "In Latest Scan",
	'' as "Software/Database Vendor",
	'' as "Software/Database Name & Version",
	'' as "Patch Level",
	'' as "Diagram Label",
	tags ->> 'Comments' as "Comments",
	arn as "Serial #/Asset Tag#",
  CASE
    WHEN vpc_list.title is null THEN aws_ec2_application_load_balancer.vpc_id
    ELSE vpc_list.title
  END as "VLAN/Network ID",
	tags ->> 'Application_Owner' as "Application Owner",
	tags ->> 'System_Owner' as "System Owner",
	tags ->> 'Function' as "Function",
	'' as "End-of-Life"
FROM
	aws_ec2_application_load_balancer
	left join vpc_list ON vpc_list.vpc_id = aws_ec2_application_load_balancer.vpc_id
	
UNION

-- Classic Load Balancer
SELECT
	aws_ec2_classic_load_balancer.title as "Unique Asset Identifier",
	'' as "IPv4 or IPv6 Address",
	'Yes' as "Virtual",
	    tags ->> 'Public' as "Public",		

--CASE
--	WHEN scheme = 'internet-facing' THEN 'Yes'
--		ELSE 'No'
--	END as "Public",
	dns_name as "DNS Name or URL",
	'' as "NetBIOS Name",
	'' as "MAC Address",
	tags ->> 'Authenticated_Scan' as "Authenticated Scan",
	tags ->> 'Baseline_Configuration_Name' as "Baseline Configuration Name",
	'' as "OS Name and Version",
	'' as "Location",
	'AWS Load Balancer' as "Asset Type",
	'' as "Hardware Make/Model",
	'' as "In Latest Scan",
	'' as "Software/Database Vendor",
	'' as "Software/Database Name & Version",
	'' as "Patch Level",
	'' as "Diagram Label",
	tags ->> 'Comments' as "Comments",
	arn as "Serial #/Asset Tag#",
 CASE
    WHEN vpc_list.title is null THEN aws_ec2_classic_load_balancer.vpc_id
    ELSE vpc_list.title
 END as "VLAN/Network ID",
	tags ->> 'Application_Owner' as "Application Owner",
	tags ->> 'System_Owner' as "System Owner",
	tags ->> 'Function' as "Function",
	'' as "End-of-Life"
FROM
	aws_ec2_classic_load_balancer
	left join vpc_list ON vpc_list.vpc_id = aws_ec2_classic_load_balancer.vpc_id
	
	-- Directory Service	
	UNION
	
	SELECT
	aws_directory_service_directory.title as "Unique Asset Identifier",
	jsonb_array_elements_text(dns_ip_addrs) "IPv4 or IPv6 Address",
	'Yes' as "Virtual",
    tags ->> 'Public' as "Public",		
	--'' as "Public",
	access_url as "DNS Name or URL",
	directory_id as "NetBIOS Name",
	'' as "MAC Address",
	tags ->> 'Authenticated_Scan' as "Authenticated Scan",
	tags ->> 'Baseline_Configuration_Name' as "Baseline Configuration Name",
	'' as "OS Name and Version",
	region as "Location",
	'AWS Directory Service' as "Asset Type",
	'' as "Hardware Make/Model",
	'' as "In Latest Scan",
	type as "Software/Database Vendor",
	edition as "Software/Database Name & Version",
	'' as "Patch Level",
	'' as "Diagram Label",
	tags ->> 'Comments' as "Comments",
	arn as "Serial #/Asset Tag#",
  CASE
    WHEN vpc_list.title is null THEN vpc_settings ->> 'VpcId'
    ELSE vpc_list.title
  END as "VLAN/Network ID",
	tags ->> 'System_Owner' as "System Administrator/Owner",
	tags ->> 'Application_Owner' as "Application Administrator/Owner",
	tags ->> 'Function' as "Function",
	'' as "End-of-Life"
FROM
	aws_directory_service_directory
	left join vpc_list ON vpc_list.vpc_id = aws_directory_service_directory.vpc_settings ->> 'VpcId'
	
	-- EC2 Fedramp Inventory
	UNION
	
select
  --instance_id as "Unique Asset Identifier",
      CASE
    WHEN aws_ec2_instance.title is not null THEN aws_ec2_instance.title
	ELSE instance_id
  END as "Unique Asset Identifier",
    CASE
    WHEN "IP_Type" = 'Private' THEN "IP"
  END as "IPv4 or IPv6 Address",
  'Yes' as "Virtual",
      tags ->> 'Public' as "Public",		
  --CASE
    --WHEN "IP_Type" = 'Public' THEN "IP"
  --END as "Public",
  private_dns_name as "DNS Name or URL",
  '' as "NetBIOS Name",
  --aws_ec2_instance.title as "NetBIOS Name",
  '' as "MAC Address",
  tags ->> 'Authenticated_Scan' as "Authenticated Scan",
  tags ->> 'Baseline_Configuration_Name' as "Baseline Configuration Name",
  platform_details as "OS Name and Version",
  placement_availability_zone as "Location",
  'AWS EC2' as "Asset Type",
  instance_type as "Hardware Make/Model",
  '' as "In Latest Scan",
  CASE
    WHEN ami_list.name is null THEN aws_ec2_instance.image_id
    ELSE ami_list.name
  END as "Software/Database Vendor",
  '' as "Software/Database Name & Version",
  '' as "Patch Level",
  '' as "Diagram Label",
  tags ->> 'Comments' as "Comments",
  aws_ec2_instance.arn as "Serial #/Asset Tag#",
  vpc_list.title as "VLAN/Network ID",
  tags ->> 'Application_Owner' as "Application Owner",
  tags ->> 'System_Owner' as "System Owner",
  tags ->> 'Function' as "Function",
  '' as "End-of-Life"
from
  aws_ec2_instance
  left join all_ips ON all_ips.attached_instance_id = aws_ec2_instance.instance_id
  left join vpc_list ON vpc_list.vpc_id = aws_ec2_instance.vpc_id
  left join ami_list ON ami_list.image_id = aws_ec2_instance.image_id
where
  instance_state = 'running'
	
	-- FSX File System
	UNION
	
	SELECT
  "Unique Asset Identifier",
  CASE
    WHEN all_ips."IP_Type" = 'Private' THEN "IP"
  END as "IPv4 or IPv6 Address",
  	'Yes' as "Virtual",
	'' as "Public",
  --CASE
    --WHEN all_ips."IP_Type" = 'Public' THEN all_ips."IP"
  --END as "Public",
  "DNS Name or URL",
  '' as "NetBIOS Name",
  '' as "MAC Address",
  "Authenticated Scan",
  "Baseline Configuration Name",
  '' as "OS Name and Version",
  '' as "Location",
  'AWS ALB' as "Asset Type",
  '' as "Hardware Make/Model",
  '' as "In Latest Scan",
  '' as "Software/Database Vendor",
  '' as "Software/Database Name & Version",
  '' as "Patch Level",
  '' as "Diagram Label",
  "Comments",
  '' as "Serial #/Asset Tag#",
  "VLAN/Network ID",
  "Application Owner",
  "System Owner",
  "Function",
  "End-of-Life"
FROM
  fsx_data
  inner join all_ips ON all_ips.network_interface_id = fsx_data.interface
  
  
  --Internet Gateway
UNION

 SELECT
	aws_vpc_internet_gateway.title as "Unique Asset Identifier",
	'' as "IPv4 or IPv6 Address",
	'Yes' as "Virtual",
    tags ->> 'Public' as "Public",		
	--'' as "Public",
	'' as "DNS Name or URL",
	internet_gateway_id as "NetBIOS Name",
	'' as "MAC Address",
	tags ->> 'Authenticated_Scan' as "Authenticated Scan",
	tags ->> 'Baseline_Configuration_Name' as "Baseline Configuration Name",
	'' as "OS Name and Version",
	region as "Location",
	'AWS Internet Gateway' as "Asset Type",
	'' as "Hardware Make/Model",
	'' as "In Latest Scan",
	'' as "Software/Database Vendor",
	'' as "Software/Database Name & Version",
	'' as "Patch Level",
	'' as "Diagram Label",
	tags ->> 'Comments' as "Comments",
	jsonb_array_elements_text(akas) as "Serial #/Asset Tag#", 
	CASE
		WHEN vpc_list.title is null THEN aws_vpc_internet_gateway.attachments -> 0 ->> 'VpcId'
		ELSE vpc_list.title
	END as "VLAN/Network ID",
	tags ->> 'Application_Owner' as "Application Owner",
	tags ->> 'System_Owner' as "System Owner",
	tags ->> 'Function' as "Function",
	'' as "End-of-Life"
FROM
	aws_vpc_internet_gateway
	left join vpc_list ON vpc_list.vpc_id = aws_vpc_internet_gateway.attachments -> 0 ->> 'VpcId'
	
	--Network Load Balancer
	
	UNION
	
SELECT
	aws_ec2_network_load_balancer.title as "Unique Asset Identifier",
	'' as "IPv4 or IPv6 Address",
	'Yes' as "Virtual",
    tags ->> 'Public' as "Public",		
	--'' as "Public",
	dns_name as "DNS Name or URL",
	'' as "NetBIOS Name",
	'' as "MAC Address",
	tags ->> 'Authenticated_Scan' as "Authenticated Scan",
	tags ->> 'Baseline_Configuration_Name' as "Baseline Configuration Name",
	'' as "OS Name and Version",
	region as "Location",
	'AWS NLB' as "Asset Type",
	'' as "Hardware Make/Model",
	'' as "In Latest Scan",
	'' as "Software/Database Vendor",
	'' as "Software/Database Name & Version",
	'' as "Patch Level",
	'' as "Diagram Label",
	tags ->> 'Comments' as "Comments",
	jsonb_array_elements_text(akas) as "Serial #/Asset Tag#",
	CASE
		WHEN vpc_list.title is null THEN aws_ec2_network_load_balancer.vpc_id
		ELSE vpc_list.title
	END as "VLAN/Network ID",
	tags ->> 'Application_Owner' as "Application Owner",
	tags ->> 'System_Owner' as "System Owner",
	tags ->> 'Function' as "Function",
	'' as "End-of-Life"
FROM
	aws_ec2_network_load_balancer
	left join vpc_list ON vpc_list.vpc_id = aws_ec2_network_load_balancer.vpc_id
	
	-- Open Search
	
	UNION
	
	  SELECT
	aws_opensearch_domain.title as "Unique Asset Identifier",
	'' as "IPv4 or IPv6 Address",
	  	'Yes' as "Virtual",
    tags ->> 'Public' as "Public",		
	--'' as "Public",
	--dns_name as "DNS Name or URL",
	'' as "DNS Name or URL",
	'' as "NetBIOS Name",
	'' as "MAC Address",
	tags ->> 'Authenticated_Scan' as "Authenticated Scan",
	tags ->> 'Baseline_Configuration_Name' as "Baseline Configuration Name",
	'' as "OS Name and Version",
	'' as "Location",
	'AWS ALB' as "Asset Type",
	'' as "Hardware Make/Model",
	'' as "In Latest Scan",
	'' as "Software/Database Vendor",
	'' as "Software/Database Name & Version",
	'' as "Patch Level",
	'' as "Diagram Label",
	tags ->> 'Comments' as "Comments",
	arn as "Serial #/Asset Tag#",
  CASE
    WHEN vpc_list.title is null THEN aws_opensearch_domain.vpc_options ->> 'VPCId'
    ELSE vpc_list.title
  END as "VLAN/Network ID",
	tags ->> 'Application_Owner' as "Application Owner",
	tags ->> 'System_Owner' as "System Owner",
	tags ->> 'Function' as "Function",
	'' as "End-of-Life"
FROM
	aws_opensearch_domain
	left join vpc_list ON vpc_list.vpc_id = aws_opensearch_domain.vpc_options ->> 'VPCId'
	
	-- RDS Fedramp inventory
	
	UNION
SELECT
	text(db_instance_identifier) as "Unique Asset Identifier",
	'' as "IPv4 or IPv6 Address",
	'Yes' as "Virtual",
    tags ->> 'Public' as "Public",			
	--'publicly_accessible' as "Public",
	endpoint_address || ':' || endpoint_port as "DNS Name or URL",
	resource_id as "NetBIOS Name",
	'' as "MAC Address",
	tags ->> 'Authenticated_Scan' as "Authenticated Scan",
	tags ->> 'Baseline_Configuration_Name' as "Baseline Configuration Name",
	'' as "OS Name and Version",
	availability_zone as "Location",
	'AWS RDS' as "Asset Type",
	class as "Hardware Make/Model",
	'' as "In Latest Scan",
	engine as "Software/Database Vendor",
	engine_version as "Software/Database Name & Version",
	'' as "Patch Level",
	'' as "Diagram Label",
	tags ->> 'Comments' as "Comments",
	arn as "Serial #/Asset Tag#",
	db_subnet_group_name as "VLAN/Network ID",
	tags ->> 'Application_Owner' as "Application Owner",
	tags ->> 'System_Owner' as "System Owner",
	tags ->> 'Function' as "Function",
	'' as "End-of-Life"
FROM
	aws_rds_db_instance	
	
	-- S3 bucket inventory
	UNION
SELECT
	title as "Unique Asset Identifier",
	'' as "IPv4 or IPv6 Address",
	'Yes' as "Virtual",
    tags ->> 'Public' as "Public",		
	--'' as "Public",
	'' as "DNS Name or URL",
	'' as "NetBIOS Name",
	'' as "MAC Address",
	tags ->> 'Authenticated_Scan' as "Authenticated Scan",
	tags ->> 'Baseline_Configuration_Name' as "Baseline Configuration Name",
	'' as "OS Name and Version",
	region as "Location",
	'AWS S3' as "Asset Type",
	'' as "Hardware Make/Model",
	'' as "In Latest Scan",
	'' as "Software/Database Vendor",
	'' as "Software/Database Name & Version",
	'' as "Patch Level",
	'' as "Diagram Label",
	tags ->> 'Comments' as "Comments",
	arn as "Serial #/Asset Tag#",
	'' as "VLAN/Network ID",
	tags ->> 'Application_Owner' as "Application Owner",
	tags ->> 'System_Owner' as "System Owner",
	tags ->> 'Function' as "Function",
	'' as "End-of-Life"
FROM
	aws_s3_bucket	
	
-- Subnet VPC Inventory

UNION
SELECT
	aws_vpc_subnet.title as "Unique Asset Identifier",
	text(cidr_block) as "IPv4 or IPv6 Address",
	'Yes' as "Virtual",
    tags ->> 'Public' as "Public",		
	--'' as "Public",
	'' as "DNS Name or URL",
	subnet_id as "NetBIOS Name",
	'' as "MAC Address",
	tags ->> 'Authenticated_Scan' as "Authenticated Scan",
	tags ->> 'Baseline_Configuration_Name' as "Baseline Configuration Name",
	'' as "OS Name and Version",
	availability_zone as "Location",
	'AWS VPC Subnet' as "Asset Type",
	'' as "Hardware Make/Model",
	'' as "In Latest Scan",
	'' as "Software/Database Vendor",
	'' as "Software/Database Name & Version",
	'' as "Patch Level",
	'' as "Diagram Label",
	tags ->> 'Comments' as "Comments",
	subnet_arn as "Serial #/Asset Tag#",
 CASE
    WHEN vpc_list.title is null THEN aws_vpc_subnet.vpc_id
    ELSE vpc_list.title
 END as "VLAN/Network ID",
	tags ->> 'Application_Owner' as "Application Owner",
	tags ->> 'System_Owner' as "System Owner",
	tags ->> 'Function' as "Function",
	'' as "End-of-Life"
FROM
	aws_vpc_subnet
	left join vpc_list ON vpc_list.vpc_id = aws_vpc_subnet.vpc_id
	
	-- VPC Nat Gateway Inventory
	
UNION

SELECT
	aws_vpc_nat_gateway.title as "Unique Asset Identifier",
	'' as "IPv4 or IPv6 Address",
	'Yes' as "Virtual",
    tags ->> 'Public' as "Public",		
	--'' as "Public",
	'' as "DNS Name or URL",
	nat_gateway_id as "NetBIOS Name",
	'' as "MAC Address",
	tags ->> 'Authenticated_Scan' as "Authenticated Scan",
	tags ->> 'Baseline_Configuration_Name' as "Baseline Configuration Name",
	'' as "OS Name and Version",
	region as "Location",
	'AWS VPC NAT Gateway' as "Asset Type",
	'' as "Hardware Make/Model",
	'' as "In Latest Scan",
	'' as "Software/Database Vendor",
	'' as "Software/Database Name & Version",
	'' as "Patch Level",
	'' as "Diagram Label",
	tags ->> 'Comments' as "Comments",
	arn as "Serial #/Asset Tag#",
 CASE
    WHEN vpc_list.title is null THEN aws_vpc_nat_gateway.vpc_id
    ELSE vpc_list.title
 END as "VLAN/Network ID",
	tags ->> 'Application_Owner' as "Application Owner",
	tags ->> 'System_Owner' as "System Owner",
	tags ->> 'Function' as "Function",
	'' as "End-of-Life"
FROM
	aws_vpc_nat_gateway
	left join vpc_list ON vpc_list.vpc_id = aws_vpc_nat_gateway.vpc_id

	


	


  EOQ
  title = "AWS Fedramp Inventory"
  width = 8
}



























table {
  title = "AWS FedRAMP Inventory "
  width = 8

  sql   = <<-EOQ
WITH vpc_list as (
    SELECT DISTINCT
      vpc_id,
      title
    from
      aws_vpc
  ),
    all_ips as (
    select
	  attached_instance_id,
      network_interface_id,
      pvt_ip_addr -> 'Association' ->> 'PublicIp' as "IP",
      'Public' as "IP_Type"
    from
      aws_ec2_network_interface eni,
      jsonb_array_elements(eni.private_ip_addresses) as pvt_ip_addr
    where
      pvt_ip_addr -> 'Association' ->> 'PublicIp' is not null
    UNION ALL
    select
	  attached_instance_id,		
      network_interface_id,
      pvt_ip_addr ->> 'PrivateIpAddress' as "IP",
      'Private' as "IP_Type"
    from
      aws_ec2_network_interface eni,
      jsonb_array_elements(eni.private_ip_addresses) as pvt_ip_addr
    where
      pvt_ip_addr ->> 'PrivateIpAddress' is not null
	  and attached_instance_id is not null
  ),
  ami_list as (
    select
      image_id,
      name
    from
      aws_ec2_ami
  ),  
  network_interfaces as (
    SELECT
      file_system_id,
      jsonb_array_elements_text(network_interface_ids) "interface"
    FROM
      aws_fsx_file_system
  ),
  fsx_data as (
    SELECT
      --network_interfaces.interface,
      aws_fsx_file_system.title as "Unique Asset Identifier",
      jsonb_array_elements_text(network_interface_ids) "interface",
      --'' as "IPv4 or IPv6 Address",
      --	'' as "Public",
      dns_name as "DNS Name or URL",
      '' as "NetBIOS Name",
      '' as "MAC Address",
      tags ->> 'Authenticated_Scan' as "Authenticated Scan",
      tags ->> 'Baseline_Configuration_Name' as "Baseline Configuration Name",
      '' as "OS Name and Version",
      '' as "Location",
      'AWS ALB' as "Asset Type",
      '' as "Hardware Make/Model",
      '' as "In Latest Scan",
      '' as "Software/Database Vendor",
      '' as "Software/Database Name & Version",
      '' as "Patch Level",
      '' as "Diagram Label",
      tags ->> 'Comments' as "Comments",
      arn as "Serial #/Asset Tag#",
      CASE
        WHEN vpc_list.title is null THEN aws_fsx_file_system.vpc_id
        ELSE vpc_list.title
      END as "VLAN/Network ID",
      tags ->> 'Application_Owner' as "Application Owner",
      tags ->> 'System_Owner' as "System Owner",
      tags ->> 'Function' as "Function",
      '' as "End-of-Life"
    FROM
      aws_fsx_file_system
      INNER join vpc_list ON vpc_list.vpc_id = aws_fsx_file_system.vpc_id
  )
  
  --Application Load Balancer
  SELECT
	aws_ec2_application_load_balancer.title as "Unique Asset Identifier",
	'' as "IPv4 or IPv6 Address",
		'Yes' as "Virtual",
    tags ->> 'Public' as "Public",		
	--'' as "Public",
	dns_name as "DNS Name or URL",
	'' as "NetBIOS Name",
	'' as "MAC Address",
	tags ->> 'Authenticated_Scan' as "Authenticated Scan",
	tags ->> 'Baseline_Configuration_Name' as "Baseline Configuration Name",
	'' as "OS Name and Version",
	'' as "Location",
	'AWS ALB' as "Asset Type",
	'' as "Hardware Make/Model",
	'' as "In Latest Scan",
	'' as "Software/Database Vendor",
	'' as "Software/Database Name & Version",
	'' as "Patch Level",
	'' as "Diagram Label",
	tags ->> 'Comments' as "Comments",
	arn as "Serial #/Asset Tag#",
  CASE
    WHEN vpc_list.title is null THEN aws_ec2_application_load_balancer.vpc_id
    ELSE vpc_list.title
  END as "VLAN/Network ID",
	tags ->> 'Application_Owner' as "Application Owner",
	tags ->> 'System_Owner' as "System Owner",
	tags ->> 'Function' as "Function",
	'' as "End-of-Life"
FROM
	aws_ec2_application_load_balancer
	left join vpc_list ON vpc_list.vpc_id = aws_ec2_application_load_balancer.vpc_id
	
UNION

-- Classic Load Balancer
SELECT
	aws_ec2_classic_load_balancer.title as "Unique Asset Identifier",
	'' as "IPv4 or IPv6 Address",
	'Yes' as "Virtual",
	    tags ->> 'Public' as "Public",		

--CASE
--	WHEN scheme = 'internet-facing' THEN 'Yes'
--		ELSE 'No'
--	END as "Public",
	dns_name as "DNS Name or URL",
	'' as "NetBIOS Name",
	'' as "MAC Address",
	tags ->> 'Authenticated_Scan' as "Authenticated Scan",
	tags ->> 'Baseline_Configuration_Name' as "Baseline Configuration Name",
	'' as "OS Name and Version",
	'' as "Location",
	'AWS Load Balancer' as "Asset Type",
	'' as "Hardware Make/Model",
	'' as "In Latest Scan",
	'' as "Software/Database Vendor",
	'' as "Software/Database Name & Version",
	'' as "Patch Level",
	'' as "Diagram Label",
	tags ->> 'Comments' as "Comments",
	arn as "Serial #/Asset Tag#",
 CASE
    WHEN vpc_list.title is null THEN aws_ec2_classic_load_balancer.vpc_id
    ELSE vpc_list.title
 END as "VLAN/Network ID",
	tags ->> 'Application_Owner' as "Application Owner",
	tags ->> 'System_Owner' as "System Owner",
	tags ->> 'Function' as "Function",
	'' as "End-of-Life"
FROM
	aws_ec2_classic_load_balancer
	left join vpc_list ON vpc_list.vpc_id = aws_ec2_classic_load_balancer.vpc_id
	
	-- Directory Service	
	UNION
	
	SELECT
	aws_directory_service_directory.title as "Unique Asset Identifier",
	jsonb_array_elements_text(dns_ip_addrs) "IPv4 or IPv6 Address",
	'Yes' as "Virtual",
    tags ->> 'Public' as "Public",		
	--'' as "Public",
	access_url as "DNS Name or URL",
	directory_id as "NetBIOS Name",
	'' as "MAC Address",
	tags ->> 'Authenticated_Scan' as "Authenticated Scan",
	tags ->> 'Baseline_Configuration_Name' as "Baseline Configuration Name",
	'' as "OS Name and Version",
	region as "Location",
	'AWS Directory Service' as "Asset Type",
	'' as "Hardware Make/Model",
	'' as "In Latest Scan",
	type as "Software/Database Vendor",
	edition as "Software/Database Name & Version",
	'' as "Patch Level",
	'' as "Diagram Label",
	tags ->> 'Comments' as "Comments",
	arn as "Serial #/Asset Tag#",
  CASE
    WHEN vpc_list.title is null THEN vpc_settings ->> 'VpcId'
    ELSE vpc_list.title
  END as "VLAN/Network ID",
	tags ->> 'System_Owner' as "System Administrator/Owner",
	tags ->> 'Application_Owner' as "Application Administrator/Owner",
	tags ->> 'Function' as "Function",
	'' as "End-of-Life"
FROM
	aws_directory_service_directory
	left join vpc_list ON vpc_list.vpc_id = aws_directory_service_directory.vpc_settings ->> 'VpcId'
	
	-- EC2 Fedramp Inventory
	UNION
	
select
  --instance_id as "Unique Asset Identifier",
      CASE
    WHEN aws_ec2_instance.title is not null THEN aws_ec2_instance.title
	ELSE instance_id
  END as "Unique Asset Identifier",
    CASE
    WHEN "IP_Type" = 'Private' THEN "IP"
  END as "IPv4 or IPv6 Address",
  'Yes' as "Virtual",
      tags ->> 'Public' as "Public",		
  --CASE
    --WHEN "IP_Type" = 'Public' THEN "IP"
  --END as "Public",
  private_dns_name as "DNS Name or URL",
  '' as "NetBIOS Name",
  --aws_ec2_instance.title as "NetBIOS Name",
  '' as "MAC Address",
  tags ->> 'Authenticated_Scan' as "Authenticated Scan",
  tags ->> 'Baseline_Configuration_Name' as "Baseline Configuration Name",
  platform_details as "OS Name and Version",
  placement_availability_zone as "Location",
  'AWS EC2' as "Asset Type",
  instance_type as "Hardware Make/Model",
  '' as "In Latest Scan",
  CASE
    WHEN ami_list.name is null THEN aws_ec2_instance.image_id
    ELSE ami_list.name
  END as "Software/Database Vendor",
  '' as "Software/Database Name & Version",
  '' as "Patch Level",
  '' as "Diagram Label",
  tags ->> 'Comments' as "Comments",
  aws_ec2_instance.arn as "Serial #/Asset Tag#",
  vpc_list.title as "VLAN/Network ID",
  tags ->> 'Application_Owner' as "Application Owner",
  tags ->> 'System_Owner' as "System Owner",
  tags ->> 'Function' as "Function",
  '' as "End-of-Life"
from
  aws_ec2_instance
  left join all_ips ON all_ips.attached_instance_id = aws_ec2_instance.instance_id
  left join vpc_list ON vpc_list.vpc_id = aws_ec2_instance.vpc_id
  left join ami_list ON ami_list.image_id = aws_ec2_instance.image_id
where
  instance_state = 'running'
	
	-- FSX File System
	UNION
	
	SELECT
  "Unique Asset Identifier",
  CASE
    WHEN all_ips."IP_Type" = 'Private' THEN "IP"
  END as "IPv4 or IPv6 Address",
  	'Yes' as "Virtual",
	'' as "Public",
  --CASE
    --WHEN all_ips."IP_Type" = 'Public' THEN all_ips."IP"
  --END as "Public",
  "DNS Name or URL",
  '' as "NetBIOS Name",
  '' as "MAC Address",
  "Authenticated Scan",
  "Baseline Configuration Name",
  '' as "OS Name and Version",
  '' as "Location",
  'AWS ALB' as "Asset Type",
  '' as "Hardware Make/Model",
  '' as "In Latest Scan",
  '' as "Software/Database Vendor",
  '' as "Software/Database Name & Version",
  '' as "Patch Level",
  '' as "Diagram Label",
  "Comments",
  '' as "Serial #/Asset Tag#",
  "VLAN/Network ID",
  "Application Owner",
  "System Owner",
  "Function",
  "End-of-Life"
FROM
  fsx_data
  inner join all_ips ON all_ips.network_interface_id = fsx_data.interface
  
  
  --Internet Gateway
UNION

 SELECT
	aws_vpc_internet_gateway.title as "Unique Asset Identifier",
	'' as "IPv4 or IPv6 Address",
	'Yes' as "Virtual",
    tags ->> 'Public' as "Public",		
	--'' as "Public",
	'' as "DNS Name or URL",
	internet_gateway_id as "NetBIOS Name",
	'' as "MAC Address",
	tags ->> 'Authenticated_Scan' as "Authenticated Scan",
	tags ->> 'Baseline_Configuration_Name' as "Baseline Configuration Name",
	'' as "OS Name and Version",
	region as "Location",
	'AWS Internet Gateway' as "Asset Type",
	'' as "Hardware Make/Model",
	'' as "In Latest Scan",
	'' as "Software/Database Vendor",
	'' as "Software/Database Name & Version",
	'' as "Patch Level",
	'' as "Diagram Label",
	tags ->> 'Comments' as "Comments",
	jsonb_array_elements_text(akas) as "Serial #/Asset Tag#", 
	CASE
		WHEN vpc_list.title is null THEN aws_vpc_internet_gateway.attachments -> 0 ->> 'VpcId'
		ELSE vpc_list.title
	END as "VLAN/Network ID",
	tags ->> 'Application_Owner' as "Application Owner",
	tags ->> 'System_Owner' as "System Owner",
	tags ->> 'Function' as "Function",
	'' as "End-of-Life"
FROM
	aws_vpc_internet_gateway
	left join vpc_list ON vpc_list.vpc_id = aws_vpc_internet_gateway.attachments -> 0 ->> 'VpcId'
	
	--Network Load Balancer
	
	UNION
	
SELECT
	aws_ec2_network_load_balancer.title as "Unique Asset Identifier",
	'' as "IPv4 or IPv6 Address",
	'Yes' as "Virtual",
    tags ->> 'Public' as "Public",		
	--'' as "Public",
	dns_name as "DNS Name or URL",
	'' as "NetBIOS Name",
	'' as "MAC Address",
	tags ->> 'Authenticated_Scan' as "Authenticated Scan",
	tags ->> 'Baseline_Configuration_Name' as "Baseline Configuration Name",
	'' as "OS Name and Version",
	region as "Location",
	'AWS NLB' as "Asset Type",
	'' as "Hardware Make/Model",
	'' as "In Latest Scan",
	'' as "Software/Database Vendor",
	'' as "Software/Database Name & Version",
	'' as "Patch Level",
	'' as "Diagram Label",
	tags ->> 'Comments' as "Comments",
	jsonb_array_elements_text(akas) as "Serial #/Asset Tag#",
	CASE
		WHEN vpc_list.title is null THEN aws_ec2_network_load_balancer.vpc_id
		ELSE vpc_list.title
	END as "VLAN/Network ID",
	tags ->> 'Application_Owner' as "Application Owner",
	tags ->> 'System_Owner' as "System Owner",
	tags ->> 'Function' as "Function",
	'' as "End-of-Life"
FROM
	aws_ec2_network_load_balancer
	left join vpc_list ON vpc_list.vpc_id = aws_ec2_network_load_balancer.vpc_id
	
	-- Open Search
	
	UNION
	
	  SELECT
	aws_opensearch_domain.title as "Unique Asset Identifier",
	'' as "IPv4 or IPv6 Address",
	  	'Yes' as "Virtual",
    tags ->> 'Public' as "Public",		
	--'' as "Public",
	--dns_name as "DNS Name or URL",
	'' as "DNS Name or URL",
	'' as "NetBIOS Name",
	'' as "MAC Address",
	tags ->> 'Authenticated_Scan' as "Authenticated Scan",
	tags ->> 'Baseline_Configuration_Name' as "Baseline Configuration Name",
	'' as "OS Name and Version",
	'' as "Location",
	'AWS ALB' as "Asset Type",
	'' as "Hardware Make/Model",
	'' as "In Latest Scan",
	'' as "Software/Database Vendor",
	'' as "Software/Database Name & Version",
	'' as "Patch Level",
	'' as "Diagram Label",
	tags ->> 'Comments' as "Comments",
	arn as "Serial #/Asset Tag#",
  CASE
    WHEN vpc_list.title is null THEN aws_opensearch_domain.vpc_options ->> 'VPCId'
    ELSE vpc_list.title
  END as "VLAN/Network ID",
	tags ->> 'Application_Owner' as "Application Owner",
	tags ->> 'System_Owner' as "System Owner",
	tags ->> 'Function' as "Function",
	'' as "End-of-Life"
FROM
	aws_opensearch_domain
	left join vpc_list ON vpc_list.vpc_id = aws_opensearch_domain.vpc_options ->> 'VPCId'
	
	-- RDS Fedramp inventory
	
	UNION
SELECT
	text(db_instance_identifier) as "Unique Asset Identifier",
	'' as "IPv4 or IPv6 Address",
	'Yes' as "Virtual",
    tags ->> 'Public' as "Public",			
	--'publicly_accessible' as "Public",
	endpoint_address || ':' || endpoint_port as "DNS Name or URL",
	resource_id as "NetBIOS Name",
	'' as "MAC Address",
	tags ->> 'Authenticated_Scan' as "Authenticated Scan",
	tags ->> 'Baseline_Configuration_Name' as "Baseline Configuration Name",
	'' as "OS Name and Version",
	availability_zone as "Location",
	'AWS RDS' as "Asset Type",
	class as "Hardware Make/Model",
	'' as "In Latest Scan",
	engine as "Software/Database Vendor",
	engine_version as "Software/Database Name & Version",
	'' as "Patch Level",
	'' as "Diagram Label",
	tags ->> 'Comments' as "Comments",
	arn as "Serial #/Asset Tag#",
	db_subnet_group_name as "VLAN/Network ID",
	tags ->> 'Application_Owner' as "Application Owner",
	tags ->> 'System_Owner' as "System Owner",
	tags ->> 'Function' as "Function",
	'' as "End-of-Life"
FROM
	aws_rds_db_instance	
	
	-- S3 bucket inventory
	UNION
SELECT
	title as "Unique Asset Identifier",
	'' as "IPv4 or IPv6 Address",
	'Yes' as "Virtual",
    tags ->> 'Public' as "Public",		
	--'' as "Public",
	'' as "DNS Name or URL",
	'' as "NetBIOS Name",
	'' as "MAC Address",
	tags ->> 'Authenticated_Scan' as "Authenticated Scan",
	tags ->> 'Baseline_Configuration_Name' as "Baseline Configuration Name",
	'' as "OS Name and Version",
	region as "Location",
	'AWS S3' as "Asset Type",
	'' as "Hardware Make/Model",
	'' as "In Latest Scan",
	'' as "Software/Database Vendor",
	'' as "Software/Database Name & Version",
	'' as "Patch Level",
	'' as "Diagram Label",
	tags ->> 'Comments' as "Comments",
	arn as "Serial #/Asset Tag#",
	'' as "VLAN/Network ID",
	tags ->> 'Application_Owner' as "Application Owner",
	tags ->> 'System_Owner' as "System Owner",
	tags ->> 'Function' as "Function",
	'' as "End-of-Life"
FROM
	aws_s3_bucket	
	
-- Subnet VPC Inventory

UNION
SELECT
	aws_vpc_subnet.title as "Unique Asset Identifier",
	text(cidr_block) as "IPv4 or IPv6 Address",
	'Yes' as "Virtual",
    tags ->> 'Public' as "Public",		
	--'' as "Public",
	'' as "DNS Name or URL",
	subnet_id as "NetBIOS Name",
	'' as "MAC Address",
	tags ->> 'Authenticated_Scan' as "Authenticated Scan",
	tags ->> 'Baseline_Configuration_Name' as "Baseline Configuration Name",
	'' as "OS Name and Version",
	availability_zone as "Location",
	'AWS VPC Subnet' as "Asset Type",
	'' as "Hardware Make/Model",
	'' as "In Latest Scan",
	'' as "Software/Database Vendor",
	'' as "Software/Database Name & Version",
	'' as "Patch Level",
	'' as "Diagram Label",
	tags ->> 'Comments' as "Comments",
	subnet_arn as "Serial #/Asset Tag#",
 CASE
    WHEN vpc_list.title is null THEN aws_vpc_subnet.vpc_id
    ELSE vpc_list.title
 END as "VLAN/Network ID",
	tags ->> 'Application_Owner' as "Application Owner",
	tags ->> 'System_Owner' as "System Owner",
	tags ->> 'Function' as "Function",
	'' as "End-of-Life"
FROM
	aws_vpc_subnet
	left join vpc_list ON vpc_list.vpc_id = aws_vpc_subnet.vpc_id
	
	-- VPC Nat Gateway Inventory
	
UNION

SELECT
	aws_vpc_nat_gateway.title as "Unique Asset Identifier",
	'' as "IPv4 or IPv6 Address",
	'Yes' as "Virtual",
    tags ->> 'Public' as "Public",		
	--'' as "Public",
	'' as "DNS Name or URL",
	nat_gateway_id as "NetBIOS Name",
	'' as "MAC Address",
	tags ->> 'Authenticated_Scan' as "Authenticated Scan",
	tags ->> 'Baseline_Configuration_Name' as "Baseline Configuration Name",
	'' as "OS Name and Version",
	region as "Location",
	'AWS VPC NAT Gateway' as "Asset Type",
	'' as "Hardware Make/Model",
	'' as "In Latest Scan",
	'' as "Software/Database Vendor",
	'' as "Software/Database Name & Version",
	'' as "Patch Level",
	'' as "Diagram Label",
	tags ->> 'Comments' as "Comments",
	arn as "Serial #/Asset Tag#",
 CASE
    WHEN vpc_list.title is null THEN aws_vpc_nat_gateway.vpc_id
    ELSE vpc_list.title
 END as "VLAN/Network ID",
	tags ->> 'Application_Owner' as "Application Owner",
	tags ->> 'System_Owner' as "System Owner",
	tags ->> 'Function' as "Function",
	'' as "End-of-Life"
FROM
	aws_vpc_nat_gateway
	left join vpc_list ON vpc_list.vpc_id = aws_vpc_nat_gateway.vpc_id

	


  EOQ
}

}

