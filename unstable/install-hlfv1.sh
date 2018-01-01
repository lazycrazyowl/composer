ME=`basename "$0"`
if [ "${ME}" = "install-hlfv1.sh" ]; then
  echo "Please re-run as >   cat install-hlfv1.sh | bash"
  exit 1
fi
(cat > composer.sh; chmod +x composer.sh; exec bash composer.sh)
#!/bin/bash
set -e

# Docker stop function
function stop()
{
P1=$(docker ps -q)
if [ "${P1}" != "" ]; then
  echo "Killing all running containers"  &2> /dev/null
  docker kill ${P1}
fi

P2=$(docker ps -aq)
if [ "${P2}" != "" ]; then
  echo "Removing all containers"  &2> /dev/null
  docker rm ${P2} -f
fi
}

if [ "$1" == "stop" ]; then
 echo "Stopping all Docker containers" >&2
 stop
 exit 0
fi

# Get the current directory.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Get the full path to this script.
SOURCE="${DIR}/composer.sh"

# Create a work directory for extracting files into.
WORKDIR="$(pwd)/composer-data"
rm -rf "${WORKDIR}" && mkdir -p "${WORKDIR}"
cd "${WORKDIR}"

# Find the PAYLOAD: marker in this script.
PAYLOAD_LINE=$(grep -a -n '^PAYLOAD:$' "${SOURCE}" | cut -d ':' -f 1)
echo PAYLOAD_LINE=${PAYLOAD_LINE}

# Find and extract the payload in this script.
PAYLOAD_START=$((PAYLOAD_LINE + 1))
echo PAYLOAD_START=${PAYLOAD_START}
tail -n +${PAYLOAD_START} "${SOURCE}" | tar -xzf -

# stop all the docker containers
stop



# run the fabric-dev-scripts to get a running fabric
./fabric-dev-servers/downloadFabric.sh
./fabric-dev-servers/startFabric.sh

# pull and tage the correct image for the installer
docker pull hyperledger/composer-playground:0.16.2
docker tag hyperledger/composer-playground:0.16.2 hyperledger/composer-playground:latest

# Start all composer
docker-compose -p composer -f docker-compose-playground.yml up -d

# manually create the card store
docker exec composer mkdir /home/composer/.composer

# build the card store locally first
rm -fr /tmp/onelinecard
mkdir /tmp/onelinecard
mkdir /tmp/onelinecard/cards
mkdir /tmp/onelinecard/client-data
mkdir /tmp/onelinecard/cards/PeerAdmin@hlfv1
mkdir /tmp/onelinecard/client-data/PeerAdmin@hlfv1
mkdir /tmp/onelinecard/cards/PeerAdmin@hlfv1/credentials

# copy the various material into the local card store
cd fabric-dev-servers/fabric-scripts/hlfv1/composer
cp creds/* /tmp/onelinecard/client-data/PeerAdmin@hlfv1
cp crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/signcerts/Admin@org1.example.com-cert.pem /tmp/onelinecard/cards/PeerAdmin@hlfv1/credentials/certificate
cp crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/keystore/114aab0e76bf0c78308f89efc4b8c9423e31568da0c340ca187a9b17aa9a4457_sk /tmp/onelinecard/cards/PeerAdmin@hlfv1/credentials/privateKey
echo '{"version":1,"userName":"PeerAdmin","roles":["PeerAdmin", "ChannelAdmin"]}' > /tmp/onelinecard/cards/PeerAdmin@hlfv1/metadata.json
echo '{
    "type": "hlfv1",
    "name": "hlfv1",
    "orderers": [
       { "url" : "grpc://orderer.example.com:7050" }
    ],
    "ca": { "url": "http://ca.org1.example.com:7054",
            "name": "ca.org1.example.com"
    },
    "peers": [
        {
            "requestURL": "grpc://peer0.org1.example.com:7051",
            "eventURL": "grpc://peer0.org1.example.com:7053"
        }
    ],
    "channel": "composerchannel",
    "mspID": "Org1MSP",
    "timeout": 300
}' > /tmp/onelinecard/cards/PeerAdmin@hlfv1/connection.json

# transfer the local card store into the container
cd /tmp/onelinecard
tar -cv * | docker exec -i composer tar x -C /home/composer/.composer
rm -fr /tmp/onelinecard

cd "${WORKDIR}"

# Wait for playground to start
sleep 5

# Kill and remove any running Docker containers.
##docker-compose -p composer kill
##docker-compose -p composer down --remove-orphans

# Kill any other Docker containers.
##docker ps -aq | xargs docker rm -f

# Open the playground in a web browser.
case "$(uname)" in
"Darwin") open http://localhost:8080
          ;;
"Linux")  if [ -n "$BROWSER" ] ; then
	       	        $BROWSER http://localhost:8080
	        elif    which xdg-open > /dev/null ; then
	                xdg-open http://localhost:8080
          elif  	which gnome-open > /dev/null ; then
	                gnome-open http://localhost:8080
          #elif other types blah blah
	        else
    	            echo "Could not detect web browser to use - please launch Composer Playground URL using your chosen browser ie: <browser executable name> http://localhost:8080 or set your BROWSER variable to the browser launcher in your PATH"
	        fi
          ;;
*)        echo "Playground not launched - this OS is currently not supported "
          ;;
esac

echo
echo "--------------------------------------------------------------------------------------"
echo "Hyperledger Fabric and Hyperledger Composer installed, and Composer Playground launched"
echo "Please use 'composer.sh' to re-start, and 'composer.sh stop' to shutdown all the Fabric and Composer docker images"

# Exit; this is required as the payload immediately follows.
exit 0
PAYLOAD:
� �4JZ �<KlIv���Ճ$Nf�1�@��36���O�G7?�h��HQ�eǫivɖ�������^�%�I	0� � �9�l� 2��r�%A�yU�l6)ʒmY��,�f���{�^�_}�US9�vL1������˃�mz�t�wΧ�P2��MfE>�KKRH�#$EQL%E�8!#f�� ���?�x�+������wZ�7�b��L#����8�����`'�q�:a����e��f`{ϐ�8��F�+���3���c���İ=�R�2m�a(��k��"�#�]���L�����%{�� q�Ŷ!��n����ܛ��7��䦭)1���6$Ν��l6}��C	�?�ʂ���t��>wN�������?��B��N�h��O�<�I�̿ $�"hA���lJ����(�'���h�N�sL�V0�.\G�JT�&���業�����z���,�nD�ի�����MY�6������@��ViL���X̲qK�n��Y��0�7-�oj�b�.�m����iv��^����/K�_L�|:���O�af�R����#b����I!r;��4�F�P����!�J�l�04�=J
.�並u����6���*U!d9(�����#b�����(E�o��vX�(��n��Ӊ"tU�%@a���$Ud(�3�Ҁ�8N\SO�^'��?Y��(Bk�ψW�a��,�A��zPc Tf�#�}�O��v:�����!��Ӧ�f6;2f�����d��(�G,W�:R�sr��� 9�����>�	�����C�[���x+
���}tI@W�4�v"��&<���p�[��覎e#�XqQ��)dZtr>CQ�=:�שr���
G}�cT�e%Ģ78���pF��G��ļ��[Q��_� 4I�5��5m,ܾ=�� 2��>ށ�p���~=vd�SM����Z����5����_ŉ�?�Y���r����Ѭ�H�b���<'�ؿ�J&��� �ɔ �d��g�3�����">ĺiu����Ql�rQR�)���lS�%9$����d9�g�8H~L{���F@c����U��7˟�k�~7>�����������!�g�K4W�A��"�����N��Uި��?e�~�;�4y���[��;^���C!
�}�q��;,G�f�;�d�����-�7�d�r�߭�To�5ʕ��v�d�����.��u�d�΍cC�,��HZh��k?x�ǖ�\�F*���ѣGha*����ǏQ�"��剬�P2q^���(��x�f�H }�LN�@� |��D��c�$��j �q-�<~�N��dS��%+����;�q.4��_���?A�� ���B�NQ���������L.J�k4��Ǖ!z��������qA`�*fF�7�a"�b�F��$L �B���E���Y�M6|��.�͵=L�l�	/P��:��mX��bU������ZN.����׌+f71���5M݉����%${nǴ��Bnp0�tM��t	�f��11γ�<虶�@�#�R��˦n*JG֌a�c��+ �<��|�5n��t5&�JG;���[(#?-M�(δ5A*��G�y����C8	$��d|).�!����ƚ�x�ݰ	��oY�h���B�s�����*�������0��Qf����L=�7��<�	�Ϥ�ə�_D����]�ؿbcȹ71�%���^����a�G~�9�O���Ŕ�����D�.t7m�,)_��f�b&;a�?;���r��OoU����F��CSՉ��ز�m*j�f�q!��ocx�oz,B3's^e��Ol��:�����3����(��?=�^EN����!+�R"��I������/g��Wx+���������B6MΉD1;[�_L���["ǰ��Z���۶i�B���!�ەՉs�6�9nۑ������cg���mɡ���G1���(Ft�q�X�vU27��A���.�1m�'��3Y���!7!�`*>MB]S�Ǳ��r�ҧ�5�΢�qܦl;xO����q�:$�y��Q��"�ϫ&77�.t
�>���\,���u�<έ��m��+���քnf����HEe�#�big��Q,������6�朎�r�9z��8�h��2 y��2�t�+��٢��E�˫�|�<y6�zam�s�&������G����O亸QX/��V��J�����P/����
&/���5^�7�I�C%�@�G�(֢o�������xhpO�N��3<\0͠zg���:��	n��>ہ�ނ����s��|��6�Įg|�_�qt�-��04���3�_6!�̷�ɠu�-�Xس��z:"�����ud��:�_c�}� |ܴ�B3�&G��z�/!P�KX��@sY>ͣ��L:�3���2qZl������q�O��kj�I,��C��������F���Y5�lm6�+��M���|���c%`eq����LR" �3	f��kN=N�_��+;l���U^6��Z���1�^y���zӁ�--g��^�V�i�?y?���*PH��(���ͣ-x"���r���'	�h���r�6EO�������Q�RP�s-�;�R}�'�1G�tL�q���z���i���z)�8|��~{)���t��ԮoZg協3�� /~qg����l��.�������@>����W�3I޿�K>�C�Riq��s!�X�5��v�E�|���8� ~�I������I��,>��c�^ceB��� ���W��b�7΅�G�?@������ja�[0��l���k18u�j��=T�`��*��
a_��dY�)�K�2��|eoc�2����=.D�K(�a����*6��_LBȯύ�}�i}��琜1��-ڑ�6�ƚ؇���0h- �i��ם�2�qp�)�mal��
�Ma"7�n &Y��)��фZ_Z<���R�-L���#��F���¾��*�^|��u�u�Q�t5��o��4]��@�mL;)`l{H3B��P�u���������
h�&����<��8�
��#Tv��1=]E��E�9X��i��U�ɫ�C@`����ŀ�l�-*(،��������G����%�'��9y%�a��c�3[��E]�
���,4�4�sЧJ?b.��\$��,�)V"���`�h�� �0
���ل{�qM����C���D�t'@�P�; �5c(a���!1��f��l��"&�ٚ;���� �ۄ媢Y��Cu0VJ�|�΍&��8�ߦ�����ȶ06��OV��R��{x6�\g�;2��i��v>�46��|6��E[}���&b��jI��A�超g���G�t�-  3z(���B^{��5L�	o�H����2XM���1l1�f:nى��	�-��|�5F�R�Qި>��XC%E#&� <˾�#ȏGf�L�"���D ���%\�'ڰL)p�A���_�,�A͞�hdf��������_]eM����3�'�R�7��(ݕ�ȭ9J�}�a�%U�����%�N<����]����Ŧ�2~���N����&i����ǌP���x(� ��c�Ҏ0ɳ��l��A����w�(6jT؉A����(rUX_@3�r_�z�i ���.�,�=unr���#�05�I_�Ôl~���������6	��4{�6�i�] ����d���X1�8�P�	/-�J>��&;l�4��4�;HV#�pυ�����j#��)�����	�C2�6�6�G0ؑ@҂��}��;Ʌ(�m�`X���5YUpܐ��2�a9!D��ᶃQy3G�:��M��&ܴ f��%���$�<E(jS�!��͇��x�4UA�j$&��x����d�Ü�����7�3�sw�a �.&ȡ�y1� �BDW��_�d��z�	�������;v�}
�S����Yqb�/�I���.�p��.��=����.�����ߎ���}�O��d�WR)qi����Z�[�VJY\Zʴ�KbJ��8%�T&��\J�9��^Z��Ŵ�\L�#�.��w�I�)���!;�p���/��L�+7��|�u.r|���__����8�/.]�4��r��Չ�^�W.+���.�=�w����?��_���"S��{Ư�|�����7=󬼂��>��y�S��SI~��3�����.z%W����/���G���W�e�M�����k�����W����~��_�[��K��=�p�._��%�?���}r�N/�h�'wR��bR�2/��j6��B�O��M5),�L:�7�w�Sʒ���EU�tK^\�$<���\�|�������o���?��/�����?�����܏������{?�1�ۏ"?�h��E�����;�����~�}�����"_������&�x/FJ��Z��B��(��R�Dk�J�\��
^9/�˵���Fgqq����]Z�ig��/J��v�I�`c�V+J���J��q��nq�V[-���l� $	ۥB��^W���C���v���|�����궸�K���������<*=��ֹS�5�w��VZǫ+�����u���FI��M
#�+�]��q�%�����#I����+��te��uVW��Z�_8����՝��ې��F�^���ʥ�Uܽ߷v�ͮީ�w{+m[+��!ծw;�n�R��a�~�[�Q��R?�W���;���B�����Kn��뭶)L�+����[��+�Rowm�|X>��Rm��?��R���wP��n��xp��,����'�Ľ�Sz�v{�'���.��Ny�h鎎]ie�n�~}��A����T��'�C�Z�� `�#W[��W$l��M����K0���nEZ$����T��U.�B��z�n0���+�G�E��VK���Z{Uv�'Y��^ݒא��O��û�^�Lek���ޮq��XOR�B;o	4�X�u��.�������w�R��r��E=}tS����o��T�Q�����=�](�>Е�tF>����֥UcQ:����F�=���n��Z����l%8j�j�D��TkZ%֤��T��ކ�S�9P�Ձ� ����69��rT��U�f!�Jag��/Iu���F��i��]�wO�_��K۬Miw�M˯rJw�F?�����?���Gq,=�F�Q�;;;bv5��h3)
����+��06�`l0p���m�7�`�jr��HQns��\�_D��'	�*(������=]�i��2v�9��}�s����!�������phwٰ�#��U����QU�P}z�qu訊���HBC����ɱ��1�x2G��0�s�:2�1x
_w�86_��2	��~��!�UDv�u�_9��q,TXbXq]�mY�[�P:���R�A�f���䇐�2d�:���5i���Ucjk��P}������SR��-��;яk#�`�
��P�3��kI�V}�Q�:@Ka�,0#�Q��I�6V�#��U�ZS���ЪUǵ�r1�]G���UH%@e��[�Za��:4��>�mN�8<�i$�	��6z.^��4aҥ�_�x�p��َ;��|�׉9���n0�̅�%H�BSk�v�jӂ����f��[�����z�A_&���?�v�O�N�v�M�@Z4;�#����I���.��Iع�ns n�P{�'�@�A��{v聒���S������#l��]}^����;��Mr=�["%��-�֋}DŢ��F��&��4��*:�4D���KL��+m��ɀnvW:_�s�#4����ϻ��?g�"��8lAt[P7�n'x�a1�}�8�@"cl�-㷆�:S��t��B�&]d�>7B��ǕY���`G`�\F�1'1�:�l��Z�� 6j��l�ۍ�ӄ��[����LN�z�ɰ�N��oy���^�<����g�����w� �uxO����v��!�	���B����om�vW���Wo����_W�9�t3�P��Ko{⇿:�w����^�(|~��_>rY�߾K��ա�?W��_C��s���?n��[��o�������>Je�����m̗��a��d͝*P�.9𜋘o:�WxF?�|��rM,�I��b.�9�Y9�#sA�Q���]S��u��]�*l�����|�
�H�`�wn�����ec�c"���{�R��$G�E~�t+#��&nnjz���),ٽj1���~P:$�Mm�	bm�8�=sߝVd?�rg��c�k0�k�)_����l���494g��=!y��L�\���i��pW߅�k˱�-�˔��i{b��)*�����@�߫���H��A?	��ZexV`&躻q�+ڈ1lO�6�.�������a�.i�t܎� B|�nLp��R�3w�O�b3���H�K��L��j'Q��Cz��z��p�P�OBY��%IjO5e]��z#�����"�/>x�o+�t������g:G��O��1>B�^��]�0���ԑ�S��N��Ǥ�c��X�	�cw���ߏ����#�w����2���Z�¡s����h��YiFߚ4�M�'��Z��ym6�]�^*��@k/\s_�8Ķ�nԏ[�>���R��̬p�q��2��[��"���p�Q��Z(�B�S&�]w��i�4g|s�U���5qɯT�⭋�9\��Nq|e�K��s��\�j��[�4dk]s��+�;�\5�F{�d����yR<��}E�n[-��a|���bU��\5����.��"cF`��4b^����I�ף}B5�@��$���j�Y7��
B����U�|��d��M �V��q=wF�`=w�L�[�`0�v�LZ��?���>Pty�i�S�Ő��Mj��9� �����g��M_�%�Ec�X��{j�`�:���v{���d_^o������܀#�=�j�{�+��r��-i��X��M��ő�n~�-\�w��PXtX�2���Lh�v������ۥ�Mf3��	J��\/&�K�����v���6��p_(��dg���I�~��L']����(���_��ү_�K��E�I7>��V2?����k��-�r�h\M��W�_���d4ם��0Y@S���%�E���t��_���~S��+����?~:���W�k^
_��>Gogv���Lat�I0��Cz�Y�'�&=:+u�����j�ɖU�ğ��p�H{�2O���wW��[�us���W	��G������t	��qN��
D�5�۷-Cz���Sy}v��}�����,)}�k<1��<������޷��]�}�5޹�1F��ϩࣴ����Ϟ�����OoJoJ��g~=�=���=p��㪭����߅dG�d���Gz??���W�y��y�=�3�G��׵j��M�� ���S��O��?>r��z��I��R���Zewt!@� ��?{�'/���T��'u,��y ����3������i S�w,�]}�-F �	����3�� �?!��X�M��|�ps�!�i#-������%����RH� i m�]�6�����=�?p���@��/�����l�����Y��SAN���y0�r��a��1��4 2�A���@Ϻf�\�?����i S�MB� [ ����_.��.�?
�?����U �#����	���
@�-PmT�zN���{�A.����!S�g%G������l����?3����l����3����`���"������꿱�����?3 ����_�C.�����)!��(���]����8J�ۣQw<k�ae�u���88�x�M[�g܅�g�0I�9�X��Oy����� �?���fK�l��5�w��b���͂Y��dl@�|��O]r�a0o���**i�E�h�G�����n(ܰ�$�Ն2�*���^���e�����m�Hg��;�qxS"[����VL��W��Df�؟a��b�`�2���Zà�0���[�wqSY�9C�?���2���L�� y����e�<�?���2���W|s��Y/y����Ç���+������Y�0S�bL;�ʌUߟ���*���ӏ��&tƍ��0�S�Y�[�2�"]cJ �5t�����`��f���*攖5�=�-�B�v�8,G�9��X\��:Z�b����E��q0��2�����Y}�����X��2���_ ��������0;�B���#`���������_�V�5T?ZU�?�Z^���S�'��*���n�"�Vؾ�,�1{G����m��hK��[�F�0����n=��sӲ;��=��2�n�b׋��
ao ��}�ds�;m�`��.��5X`�f��rXۮ��P�<�T�Z�]/�O���yfp����p�L����
�9�U�B�cY�]Mڝg���q�D �ѷ��/V�g����\�Ag�O:h�
���j�\�D����h�"�j�n�S����-;��ʑ�AR��+�a�b�Ei����x���mq�%ɸሰըn-��~��y�~����R�G��`��\#��l��o����\�?q���/� �E^s�������g�W�H��A���!-���_��o: ����_���`��L�?yQ����R�`�����������(rQ���O	i�?��%_ȅ��g�?� ���������������?��Kn����y����C���y�r������?��_��/`����<�?� ��e���oN �?�H�����1P�7��������?���7���AL����g��(|��/	�?d���8D� ��?s���!{��!Y�?���������K	�������w������R�� �?����C�����_@�����_� 7$3 ����_.�� �Y!O��`�##�������
��<�����#/�y�:�#��厬���mR���p�Ǣ,O�n�ik�L;�c��C9 ��/���&\V��n�7g5��o9%���r��h�d�Tt:�)Lw�$E�y�wv/l�3,�Ne[�ȸ��tgDKp�C�=J�@�'J�@�i�L�:8t�6)ia�h��l�h4�"9�����hqX	��L����qK��T��\�\$ ��%5GNi��k�d�������p�b��;#��g����
���8d� ��e�\�?q��/��!%��Aq�ԑ�O�G��T �?�����#���?���?P2K ����_.���̐+��!SG.�?�����#���?�\�B�!8�!{�7vwa4_���g��_����c�e�G��r��8�S��Q�GZ�E�-w��6��M�6B���e�%ǃ-
�<�qm�t�2�H��������c��������7[R�`���	�����/0
���n)�
N~9��q,TY��dl@�|��Sz���v��_P{�#�{Q-d�i�a��j�޸��"�8l1�t��+��]�T��Eg���U쫋}i��Ǔ	$�	).|̲��f ��r�G�vS���(�f�ԏ���r.˻&<Ң�߻���?�!�������h&}�E�?��!��d�����e�l`֟�KD�����!���\O��b7E�-`�/�q���LW�QEE�^i��A�-���Թ�lKt�X�x����#��I@�h��cʮ�Fi�Sg�5V_-d7j����(�UjN��b7�'����p���"����A �����c�qV��G��@.����� �@����_`��L���y�����f��|�V�Շ΂4g��WB��Ȍ�Kxv���g��nj ~H�����1�<�8�õ5�hiYZ��EQ��P�w��e;�a���*r�O44.aΨ_��I�ݕ1�b�H��=a�k�"��*R��e���8v���̃��ZL\�nt{u�R-֮2q2&�����έ9Qt����F·�]�AE厳gTT�_�5vzz�t��|0��L�T�!IG�_ֻ�uhK�)���=jH������klx^]�ݰ�+�6Ox/ͩ}1YF=�$��:�O�%����u���f�;�h��5�����������$��K��r��%�F�dn�^����퐮x^f��J�4/��w�v1Zf"gQD¾;e��wT�ٙ���g�؝�6AM�_0~��GA��,���/
��܃���"ſ��U_P��;���?
`�����_���@��Y�&`#:JX�'p*�I�v���_1\��a�D�<~�Htb�`Ȁ$��+/P���y���?������������J$f�	�S��N�2I�F�D��o��H'V��ٷ����ܢ�a����:<����������O�������UWP����9��H����̫�_�@�Q�H���6Ń���Ky�&!�""��L����4��l�FM	i@q!1��$xD�`?�:����/�~��k�Y*j����g�2�1ŏw�Q���C�9�l��Ә��R����.W��Z�H��Z��[���'���"=�a�WMA��o�C�����_���u�����o�����{�?�w����
~���w�&���b)��(���#�W��?������}ժP�!(����a`�#��$�`���G2����{���_��?����H�Z�o`�~�2������?����:���W�^|E@�A�+��U��u��(���ǡL�A��;��x5��aH��B���sY��s�נ�	{S�w�eG������zQ�3�.�(1�^,�*eg�^Ǽ~�[��,�ƀl�����8�gJ�{��ɴ\�}���M<f��yxQ|S��<5!�Y�C�eUdJ�s�s+��_��:0�����`>R��8�^�(��:��t���ӫ�?̊Ĕ�S-��_�|4+[H��H-~�(��蜥U��N��f��̾t��Ma��5���fY,����u��5!6����qHl�c��.{���Vj��=�~�o�]�x��RW��?�xu��)NTLj�~#>�9���R�����{Q��� S��r�J��{����`���SNs�=�q~�N֋t���/�[��Kڢ���ݼ�t�{i(���N�d.�Y�ew�lC�E�&�{�d]/#�a��7t����y�	Y�w�/v��I�&?*��߭ ��ߣ������:��,[C�������ϰ���?#�^���"H|u��4ɾ������������?X��zd5�qSR������b9x��]~u������/E��寃RC?i-1�_c:
iM���ᅥ6�,ӉJk�����=G'��k�����0o.��\�GS�s.�TFjJ�=MQ���d��g*$���{�EI=��I��4t�Q�=r�x61�9�g[S̳�����o�-m7��h��x8�1&�s��l�֐�3�۬O+g5+���H]S�U�]���vo��%�?�x�h��?\����Q�V;?8p�.	���.Jc�ݬ�I����۬9#;�F����?�SS������@�c�b��mCg��|pOhN�~�k�L2\{n9�r���l�l��:�8o��&P�����L�ೳL�1�\[��{��B-�^ ���Q���i8 $ *��׎�j��̃�/��DB���>' Ȩ��g���0�	?����������_9�����`-�Ǘ��>�>�'+9���X�L�6D��� �i�6�p �r!��k �����}���<���u �s!�x�^��a��*�9P'��6|¢�3��7���Ƕ��F.�0&�w���g���m7�}�\�B�#�|S�A�؟�`υ ���\L�(�x�	�b/�Y,i���KID\��%5l_M�^��#-�젴6!V4�1e���V�^O�L��j��	f!��ˉ����d��=c4c]����>�i+Hi*��<�R~��A-�?���Q��/�}�%�����_-��e�L��  1u��p�_p���p�������Z�ă�O�?�!�[$�b��p������:�?E>���	����F�!�pl���S8��B�Ft�GMR	E0,xD�x<!���4����wS����?"~��7��nW2�YS�-B�{���R���l���b�5y������b�Z��t�v s�ˈ^�˼&F��y`3g��Lw���,�������#2��f�=��-���U"��ܔa��[����VG����}�����Q����Q���?�6��w��Q��W����#�dN�}�)ۍ�����n��ڼ_l���m�ڟō���?'Y쇇�Һ4�^�!w��ϖ�� Oq�:l=KNĩ�o��� �;[�L'��*n�[���Q䦙�8e��v=�O���V���� �[ux�G���w|s�ԡ�������������?�U����j�����?���������{�'u�%{�]ǃb~�lp���v��{lw�Z�/�*�	��@�-3��M��-6N�l��a��Cm�	3\#h,n�[o�kE�C�H���cq��=#�3c����e/lS���󬛱�B�='�
S�K�ul�e���ی��['���n[*M��wa'eJ[���Ĺhb?m葁�5���X�q$�B���w�D��2��1kܣ��¢]�x�,��2�u�;��Vh��3I��qH��X���[��'?BC�.|C�I�=�)b-t�\'�l��7bA$�l���Fr�R�f��0�v�߷W���� ���@����5�����������$�B��W���@��0ߵ�����W��$A��Wb���5���w�+�_� �_a�+�������W��p��D��x�)���v�W�'I��*��Ê�:Q�������$@�?��C�?��������?X�RS��������:��?�x�u������0�	����������G�!�#�����	��Q ��������א�?��$�`���4��u��������/H���������4�c^����WD���!Y&��y���� :�!�����y�O� �o� �$c^Hh.!6H`��gQ��h���H����^xX\��LVS�!1f���(�ZVIO�툾��I�&���ah���&S����B��|��>~�j��Q��zEI��lU��=�T����;�X\t��+)k4�uI���d���ή�S�6�x+ux����<�Q�@��>�����������QP�'�����	����j	*����������?�����j����U��/���j����c�*4��aJ1Q���D��<ΧTD1r4��x�4Dp�)���?��LC���_��/��x������m�-�9鶩���г�G�'E�?�����g;i7��Mm%,V\�h�#�v����>f�����lNL��&�Tp����l솝�|����t��#
��8���馹lA���������@���K���������S��GA�����i� �����W�x,T�?���� ��_�P���r�j���\����$�A�a3Du����W��̫��?"��P�T�����0�	0��?����P��0��? ��_1�`7DE�����_-��a_�?�DB����E��<����``�#~���������O�D:�r�S�4��r�g�������������������ٔ����~���}��pe�'=\&^j�K3ۆ���^�C��6��]����F(W��(�.�YI��ů��Ǧto"��յ�Z��O����ODS,���r�	!��Xwk?��A���_l<����j��/h��h�3R���A	�s�w,�NZy��L��I%YMU�U|(�Ğs���p��$����}a��KlUĺ �}F�G�heM���7j���0�u��~X^���� ����Z�?� ���P3��)Q����4��f��� �?��'�����C�WU���r�ߎ/�����B���WF��_������Q��������[�$?�[����j�㦤��17˕�r�ҁ��E�b���{��)�F�I����Dg������\]��!�S{.���ENkt��LR�hվ���eB�'���rGQ��Q�x:�R��yH�'�%�kLG!�)�]=��Ԧ�e:Qi�u�tt���w{m�����ͥ���h*{�e����3MQ������ǈ�������E�EI=��I��4t�Q�=r�x61�9�g[S̳�����o�-m7��h��x8�1&�s��l�֐�3�۬O+g5+���H]S�U���[���۽ղ�h>Yu۔ĔWĹ(�r����r�0eCԥ����K�����Xm7�a�A����6k����Ap0����u�u��g����>������d�Й$4\��ӵ��Z:�מ[���73=2����9�۹�	�4�0��#S���,�w�-����F-�?�A�'�DB�Er.��.����_;����S������P+��Ӑ࢔!�g��ᙐ���0�:�C.��(�X*`�����"6b(�
�����p�?�$����ť���L���v�b�"/���"�6+QhP�R����6U����������{��4rd�
-�$�pc����Ml�ó�yE����n��d���W%��n���xoQ���VK�R��T��g[�q�:p?�^�WOΧ呛*��"���������b����)wm+_����V���6��)3��(���9�Ѻ�Q�x�����m�ϧKO=�;�v��)�s�����ӥg����?�,=�/�������K�A�o���K?��s�����fl|����{��劣�����UU����+e��l�����i&ר~(��	-O�S;�nTwD3_�Ho�֔r��"���'[};S����7S}R:�o:��Inb+͏���I6��^�n��M���3���'J�a�Wh\��?��@z翶���.m�m�m�m�m������lm�'H���goa�'���#���.��������7�Y�\��~ʟ�TRU�z�y���z�$���U����Ѳ#`m~�@�g���HО]z LU�胮\�Z����@���gf[�'�ěS�̜|5��u����E�o��w���q�nWZG�J�M���p�?�T��o��w�[��7�����[W�u�^�/�I��~�}��/��q�y�x���airV�*���%0>#ū.4Ҵx�����~4�P�t�R_�+}F������F�ݰ������߿��ޔ��~�6Y>��r��IX�i�Ϫ�˵ꇓ��{���Rz����qI�>�*�S#b�z_�|Ȏ��iQ+]��k��δ��ugh�g?:_�>�M�7�z*�qz�yw�W|ށP�ǧt��kc������O�f�[��Q�R6GSK�R+���5������٤�8_��ȋ��nV>�N5�6��Tf8ZOcV�GT�X:��rP0��@�6,�Y�Ұ�$F*�����3h�!5h_3�����T���Q
�S��s�#<�����:�B�B*�jF��6����F����)|ی���m�e�9!=�"�it�0��u�a�Q)�G$̱i;'�䝟��^7�b4���=L���e^~ƹ�^�C���?7 �!(V�4��L�☄��3�f �#]S4D$�B�_�h���%�yڵ8_�	9�2��n��j~B�)�H�����
i$�mQ�PˢSl3/�Ҙ��0��ض�!JPԙ��
]���bN�y�b_\�b�k�p���),�����A����f�!x�U������%�9�{�,3
�`�X��P�� �	��п�	N]�y+FG.�(vg�~��:{�7�ɷ��;�L���:P�ڎ��B{�9��`�}�0Z�
H B�ͷ�b�m��i��X;�m�G�g���Š�S���բh�+����<��������~S�.����W� [�](��.�V�}8��I���0�̉�'Z.J!�B�����P �*�T ��>��S	�3�e �(%�i^�_횑(Ng��FE�$*���N,��gӅ�o:�K��p�]�C>�W����#�N������%8�M_�]}hU�c��#ࣨ����u<$�u$�׍(QR"a�!C�q� �TݵA�@Wx��f�k:	O�t�C��)�ʬ��E�^�Έ�c�v(�P�v'��#�������8��qD[���+H7��@v���ȀvkZ@���[x��0��B	�&'N�8�=�,ItB�s+����lr	�1UU.a��x<��aĻ;7@k�������\3+&߱f|z���7���*��dS)�O�ҩ���GI8����2�2A ��В8̂��!�P�#f�L�OH�Qha��*�6Oœ����f$3ƚeh�����b�U+_���Ǎ��A�9Jb)XɛK*����>Ջ b	�^kdZN�Ӌ��
�Gh��A�= 1���oYL2 �xV�YNOK|-��&�]!��k6���>��vi��Mf��y���4�*I�O)���,���������J3鴺�ϲy��9�.�k�z����&$������;dr����Da���!0Шe֥�4V����r����k�Wָ7Z�j8�Z������������ʺnu�Z�S�+�V��>H�������v�}V�7*�)��N�� �s�k�X��g��j��N���g�f�r ���em�J���^����gdbZ�`�]��U 	s�$��:��m)�>X:n���★��,i�	<�z�=����/��G�P��$��B`@�r ؉%��Xlu�B������|�����J���r�UEf?�Տ.�q</P>.���Fe�h�Z:?
�pvY�W��Z�s��M!�H��S+a��4<�v�Qy�f�X󎞇�zb����&��*��	T=n�;�F��vtY�v>6Z'gлO�.�&m�ѐ�SA��\�Y�/
"�K�l��#���;U�R�K�v� �@eP)�Q��8/WJ�O��#����naw/�S%�_��'V̉)�d���< ����Tx��%�9�`Ns2����B��~\#�������w�˗��+��CWو�}	F�O�Us)~�<�j�c���,w�"�@��Es���9��%��R�<o�BS�dM�,Gup^)1d�]"�O��$������8f��t5��ltbk���̦�s���|f���(I��	Z�.BŤF9�/�돰A�;<��S�N�c%�iGRkr��,G�G��$1�uF�SB�u�r��N��5�{��|�Lfvn�@�	K��Z�x�e������uk?�֭�d����lv���(i���]�ٮ�l���?������v��i�$��2�A����@���r�v���ic��a�R͉qȿ����m����O����L6����#��[���.�xl�z�G"��,�!̲L�-Y�������<;cP����!1e��k�
���\~0)6�>�h�vR\��ӭ0�@iӚ�#h'Fw^E%�|�5�;�`;�l7�[��ɿn��u���+MTxB����-9�
�f�Ȏ�Y�[� Z��޵��suDI��( >�4�a��9gո��i�a��wV��O"�5(��vȖ���s���jd�U�#AI�;�}y��>�.��S�?R�aB�Eg��\�m,��c��C�1�����ܜ����m��������(q�uȯ9u}$�)#� �6����������u�4�O0���T���|j����r)�ͥq�'�����c���/_��m�^�&�"�0e`�h�{�_
�CY�#��؀�'�������}��e�@���@%�ǐ���t���up���J�:���]�)^�z�4ywF�́7x�Ԇ�eB����!�@�����b�U�'�&A�
�8��D�Բ�e����؂����Iv^�X�!I��o�M�_
�e'���/@��^��/���f�~�'&0��d�ͿIl���$�d��#�7�Py��W5XlF �c���Y����5�l��2��a/9x���4��G$���à1����<8 Q����x�#Ӝ�"=�����$ ��r-��Jb�?C��#�n�(�q2��Ů@�fu�$@�&W��?�b�:�&��8y����I��ʽ&�]n��<'��!�e�?�,��L�������>���*��w3ؘ��Mh��dM�)�b�V�m�p1�_�5��Ϋ�~	΃!�4�L\��1�Pɺ�$R5����e	:Hܐ(����8$�
��,v9���m�o�^� Z Q>�Eߊ̛�3-���֜�6d����L2)���a���{u `E����+�؉p�O�u|TC��7�o�ۂ�4K���PM5,�-����c��I��{�J�.V��u��un#�[��b3��pn�~�P�2;|�s%"�wɼ�W{NZ{5�����F����s�B׆�HS=�9k7�+p]�����uܘ�z�+����4Gc+�/٣����p�$eq���Z8�Ѿ5R
�L0������Aܰ���(p9_U<�
���2�*��T.|���c�кԂw���pЭ`��@ʗ'��K���[�^�s��K���v�,����J~/����������)��t�eR��=�&�L6���^��wSyJ�i6�����#w�Q����f�d>3z<c
���-5z��V�q�i�w�p������*���lv�^Z�ϙ�A�F�0YIl�z�$1�������4�c���̳��-"�d��?�3C���FG^K�R2�W���]���U�CM,B�̖�biˎ���*�;3��ǳ�T[�t�
���˘!�e�[���6��|44�l�R��K!��p5�s&�����S7FH�Ծ�6-�{��xl�.�f+@��S����O�tz����{��ƨ��I�T�ydS�ħ�G���۴2m(�?�m��?)~�+���L�v����i����tf�����x������������������`n�>����q0��T��	1dKМ�÷)P���f�}�%9�m2'�ێ$i�_o��Ͷ]�+p���)�:���Yܨ��ujaK"�b������m����
؉�4b���y��0e�Sq�O���Js�m\�AGrnaɽ����}D��	��
���N�C������^����p���
эu�.�`?��o��QJt���3�=�%��S2�B����n��=J�q�O������}5]@��Ϣ}q�
T �D�b�7qv���^w>Ϯ+��Ii���T����Is�i���㿩��S�w�؆�@�S�����t���&�"�t���T2���O���T6�C�/��d���1����ƀt/~r��"W�[�T�^��%��;�c� �]��E\2��hB��T�AQ���3�����)"���c�:6���%{d�^�����,2���������R�h�P���V�.�t�jCA�kʂá�ù*�|��"�5-���@�s��K�(,i�/Va�X����~7y чb��k+���y��-��@�>�OP�h\4q+YFƘ���x%�A���#s�P���sd�t��%�����1��SF<�+/"�PRs�=0]]%���]�U�Ӹ����W�u<�����Ϣ�rG݄�@$\�1���xA$��E� i��[���! Oc�k�}�{�tsă��8�uB��� �ZUzj*R1�θ�V�A�U� ���Y^lk�����'�&OV�~#!��	Pr�;��֫���Zx|��"�Z�3��{k�@׼	��^ - �U�J�Vd6��ԳN�/�=��B��op�ac�#�������p?yNþ~
��bS�S<������	˴mA҇m��Vא��Ft���y�tZӐ�g�<�A��*O�:���X|���n�4A���ٳ���������8�r�֨�~d�\#���"�����h*%��}l�TT3-,L0�i�O�XL瑭g���6�R��?�ˉBf�x�"��� F�g(�����n+����ă�"x�6u3�%�״wM��لh�����j1�_R^�N�[��<�*�C��̕d#�|���z���PJ�X���P| i;��}ehg�e��\��!��/�qh\28̂Gp FhF�7�L����m��5 `G�jx�>�=Wn�FB�'���/{��8���{g{k�L�4�m�.MiwA�����Zi|K�$N��΍F+'q'�ss�$�A�Bڅ�Zм�}�+�+,��@�yA<��V����*u���8L�k���������������O���<ve��,3�݇�|V���ּZ�
W�Y�[ߦ@�뵡���m5��xܱ���j�my�0} 2۽�-�//�ũ��7�y����+/��
�%��[ݺ�����E$z�Eu'���N\�D���?���?A�VO$�͓�Zf���'�/6v�����<�x��ޚ���j��e�2������`�4�z�I�d��)�FPr����)��)���T�u{^��e�<&X�fcePچ'�/6Y���>�R�tK���
+�8�)?sr<%���nD��%8w#�-��<�"|^��}�W�]��\c���6.������!HA"��?ǃ�o;������Wn�9�����_<z��_���H�cJE�u��`�ڬ5�z���f�B1�T5�0�jT���SR#�8Z��8�{���n���h�+���y� ���2�K�_�x�zz@gW����['/��������;�d��v��������7�ΗJ�q�����]�җ7�u��8QgU�����������/q��"r؅m\���E���@#���	���H�3�GJ���s�Ͽ1�+�o���3y�o��ӟ���������>A�w0�rp��-�+~���W<��"���x�C��D#M�U,� 	RC08���F�4'���8V�P\ãE���F��ť
�z�_��gݯ����'_��'2u���?|��}�a��M�Ƿ�+[��_�}��&��oB�sE�����_9���C�݇��>��j���;�:����,Kk�ul�Kֲ�hT	�f�Jh���8G�]�:�lN�8��̽���:y���F����U��/On��y��k2_��:��\A�18�"��x��ӨخLŶ�����͖eҦ�	q����2�vE�͢,�E�_ޚ�;}�R���]jV�-1_qb��X�wٽL�[�V������D�w�����⧌{��i�[�*%ĩŕq�l1�8q}Q��4Ӯ��+�:�T��,-m��s�T�$��AGB��p�Ng���6҃V8�U�v�A�?J!s;��o�Lͦc٤T�'B�h�c�̤����+�[o�����I��tt�[�J01���EeyYYqh�g�s��H�-a��Kz\��9��j�c���.�&q��È�$�{�t��4[�v:�:�w/�����aSi�LE�u�S*j��V�aH�c�Q�*�Tz��B�l��P'��b���'�!g�vg�����)F��B����G��l�{���'�ό�V1�5�L|�+�F��ҙ����/I�9Z]'���L�$��Wn�P�#paBy�)�����p��y�T��	���hj�HH�3-�b������QI�ڸMp-P��I&a�;�"i�fEMѩ��(.�U��w�h�@
#���U���u'Ֆe&-�Xx3��^|G��6�sW��t�UuL2C�a>�qR�A�[�ꂚ�a6F������Ϧz�i�WXAb�QJ" �냚\Ѱ�:��nY��	�V�J�S�&l#�zO�n&9k�b=���#R� �E1�Sac�b9id�<}Q�w�5�r!A����H�å��yb'�;��,#y�i�"���f��fg���9~�b��΁'{n"z�W(&*�=��=�=Q'�6 <��O�p-q=����j�s�؂�q29�L4�"��m�Ւ���3szT)�v�:B�r�6 6J�����A��C������%�r����i�Y���KS�J�3�y9��L,�U���A�dC �HK8O?i:1��,�|�"4���:�dG��91�R�)c�G�d�;�@��$=��L��j|<�*�RU��z4�&�6;�&۝D�.�,�l����g]��m� ����}���+�����6'�����XۍW;cc!~�\mtX�v��\ϵ`g�/B�������o�W��+OBxu�'8���}CЁۗ��ۮ9}�Ӡ?x�������п����C?y���W���C߿����q���.���ܥ��z,�;:��#��1�Y�'�e�Ѭ������e~��k�Ϣ��}݉-���ܛ���њEWx��\Gk�f.��.���u9�i.���f�G��
�T��Lˌ^_	�9"�8����a3Gb	rL�D2��sZ�-��a�I�Au�L��J"dt�\�H���vkZ}ԏ;���ѣh�4/wcI���b�:�,��%�D2~!��ʚ�Lw8F����4G��F�=2M�Ev�.48]2�Qk��k0tX7h���I�j�7ph:�*�B�U��JgN��	A�g4��Aem�ɕ�5Dn)�n�e�Lb�r�� t���Q��8u�*!�X˚}x$qM$�b,���Z�:��%����uA4��L [���_�tҰ��\�(�R%�+��t����#}�������3����k��>� ��tq� s�Lk-�fV1X�����Uf�6?�p�Y��e²�۔9�6�^Owp�����`���ʪ{����J�X�_M��mr����{d�b9{��f.�C+�<���dY-��:%CR�Zi�p`�iͮ:�n�B\�j 	9ڊl��fh�Pd2"?:G�k�H;KE�_*ʬH�Nj9Y�+9B��Kݩ��t)�	z,1��fs"K�Aʵ�ĺPFE��'�3���^0/	-ZTǩz9���բ�L�:�����9I&���:��|b�����9���f�MO�ͺ5sl�@��NF`Tf%�MΥo=�N���Ή��	�ٱ 3��Է�9�I7ZjD<��85n������ �����	��#Ɲ�0�]�Yp�_(LT�[���ί
ضy/(����b=��C#�,�x��Sf��SC>w�<;��%4:�JAG�yH�#�IS�J&�3v����xĜG�D筡'Q�+P�Z��#PH%]��#���jH~d9����jk��AG�Ą|�y7�A[i�eK�Rm:F�F�DWe�\��9z�����+�\�1���8�i�ݚ#2�Ԗ�p�s�9���z�*d93�_4�6zi�X/�%�k�x��������mNB7z��ω��W>i��<���E�����:XW<�p�[�լ�x�m���Aw���&�M�#��͖�M�p�����;�?���xu{���2��{v��/��U�h,}H7�]ћt�Wj�	�%�Q˰t�Խ Q���ڃen��}��}p���N(����\������7�po58��H�w��鉶�/O� ����&xz��Pk���+��~�u��ĭ|��\s�7Q����%�?����������w��V!Q�6#z��:��q�ɣa���z���;R�M�4V�L�ܣ��7����}?�ӥG|t�E�s%��1{�V�i`?�	cs���#)����xd���^�v�#�^�G�M�P�����Y7uD�O�(�.n�zd���Ⱥ�3�uSo�#�<w�#���#���?~~�0ݳ��a]���������?�FH�. #�/=H?��������ޅɬ/;��ה�7�����߷���%�Q�8��E\@�o�ғr
��)��(����J%�!�U�%�iI�G����j��z�X5&vx�>�W��b,O�z=�W�#�T�3�-�k�9I�g
S���˂�����u�x��L��~j����[dþ��K�;��S�?����[���z�V��o��#`������D`����Cc�����/r�����	���e�mP�'\���HaⰣzʡ$�0,8�4��a��Ԉ�����p)k�x�4'f����|J��q��%Y��'�HR2���t�1�%C�"�e�^���wV�(3)����J1���m�,���YTC�:��,�%dX�j�����x���~���k���BWj�j�_%0#P/������p��?7���6�z�#0A������o��ڸ���������c/�?��>�y��e���2�����z��\��.��O"g����/S������������_����tj~�{�������Q����������mV��D�������s��	�v�}����k�}��a_ۓ ٟs��/��O�g���Aؾ l_��i���=c�-�B������;����$X����b�{���9�?��ߝ`?����``G��F���c'"��_��~O@������p��]�O��6G� ���/������g�$��]`O��k�`����<����;A�m)ȶd[�N�%�g��^�������T�4��}E`�����^�`���=��`�O��?���������������`"��|���_G����P����/����A����� ��N��_'P��Z�lગ>�$�&�jX��6��(�idTC�Qo6k���1�`2B�����zu?����g���������/O��� �]��K���d������~
%)�C&�/��Ί�*��,Z�lEgɊBC�@���U]�f1��Vk$1x&�j�)�xM,I9=��b1�)[�A�֣ls&��2Ձ�~�xr���;�}��A�O������������a�?������e�]3����b�?���ó��U��8�ϡ�p���C�BU׆%'��f%˒c;�����K��N���ʝn�>���A��E�rG�c�Ǩ81#��d0&3�H=<H5�FRebx{f�;�A;Y��ډ�p���P�쿫b?�$X��	~������ػ��T�n{����1����} ADE���{QP�_�i��s����>IQ;Y�)1�̬9��Z+�}ŋ���������/����/���W��h�A���[�ǁ�Á7��?��O��r�lWM�x�:Q�?3�+�_N�UG��~���V��&����Ư7ۨ��m*m����\���Vw����Zw3@~���Ò$k�qPF����R:�P��&Q.�lcW��:��^�I�!�u9mwm�h�}]��*������[Y�6�:y�r]�x�M�N�����C�B>�4׫]ﻮ>h��c��_Dߎz�fۨ��,�E��R�Q/4�u�|Uuf��z>;��n�0�T�C��Hh)�ix\����7���8�3�BYU�TJ�|�^^��κ����V����Q�V`ҨU;"��|y�����ל���9	����w�?��p��C�Gr��_4�����GA���q '�C�G���7��� ��0��?��G��X��o�?��/L���Ür��{�?��en�?B�0�?�y D�������C� ��_��B��?��Z�a�� ����	���8`���@���7�.��`�����$�?F��_E����'��'8����?O_�����|��ҝ�?���l����˳X��?�����w��(�����E_�o�������
C���!����p��o�B���()���}�x����X �����������_��0�p���b�)�����#����+
���g�6�g��S�q��?���u�Z��b�G};�4j�L��֦ܯ;q�z_��W���yn���)�C��,�U��\��O5 ��'?j@�C��*�ӎo���6dKGAY�6��������F�����2ee����'�v�6ן�٠z�qb��V��\��f_��5 Ե��ԀP�"����j޹8�AcY�*F�����l>�����S���O�Ҵ�*��s�߭X��*+��z�Z23A= �=��<eC_K~4d\'���oc��"�sg��`A���C
���[�������������C�����w�?@�G�����#����?hY(��o�G���/$�?4��"�?������������`�wA(\�-�S�mv!��B ��{�?��c����q���^
'E����(�p��F틼�lĲ���D4��(�З�P�%v"���~���+����[���x����;V�b���a����YScC�5��N[�k���s�Ry�87j�I��7�qOK�����h�Hg�o��� f��t��ӪG�j8ʔҴ�^��{��i3dˍC\
�2vy�$��n/�K�\V>Mb!�p��ų<cK�׮g��i�'�Zy��(ک�^?�鹛���U�'$�����8��gK8�-$�������?
C����[�����/ŷ	���8|��K��`:��m���'4��<�5g�u�Y�a�Q9��Y�n���ح����۲I��|��_��r%g���@%٩k�!��%���ʓ��>��.��Y��~-1�r{�I��*_����Y��
2����/���������+�}�+�g��������/����/���W��h�b@���_AxK���/����i�������=dޖ^�ĺ�x����#���� ��^��q�GKC̶���LJJ�(O��i�G~��Vþ�0��P�2�ǲ��D�;���+�U/)^tP�$iݯ1��l[�r^���<��4��5�I�i��j�#Ms���_�SSu���ە���{E!Sa/9��,�����aU��nE.K��(�{]�s�����r�+6V��Y���e0�.�GV����?�"�jp��2�����k���AE���t=묧�����D�h�[q��lR|Ez�4P��T<0������ߨ�cw��Í������*����9����H���tS�!Ұ��������q�������ŉ��`�����_0��������_@b��(��E2�^O|�� �a��b��d���&2#��e��#��pP����q��������#�?���_�&��	���j�v�:*�(\6JG���h=o���JP�=����l���we��~$��̽�꿰�����;y������E��?����pS�+�,�?��ɿv�`8�K�|�'GJ��<̋��<K�b�)�$_��}�A!0�����^���X��O�H����՞�K����d7���-�����ۂM��X���m\�eZ�����5���WA��O3P�U��0ًT�Z��[��Ѱ�� �A��}�����I���������=���?�������ߊ�~��s�U����|������A�'&|���>��Т_'�>p�����+] �c 	���������\��8��8
�������������:��K���_8�C���@ ��q�wї�[���p�n���1� ��_��1��.����������!��o��y�����������T��R��+�PH�^�鯒9s�l�iNU�R�������ٗ_t�8U4���Ƈ`%$��1�5�1+v����-c|�Fa����?c[�yj�>W_�]�u�*���s��wPQ����90ʮ�?���N�z��1�ȫ�S�]^p����W$e�l����Y�^���eq���b���s�~�V��vZn�Sc,dyo;J�sΜ����2]��Zm��A�VZ���\�:�.��������)r"�J�z���j_�]�zMe�+[�"^����ՑIi��'�sP���d/W�"�j�*�+vce˭�q�͌}Oݢ�ׅ|��Ńk7��h���ɖ�:�;��Q��r���Ko�i#d�vFy)�K��'�Jq�W�I��΍�>�X�px�����uTs-���{�c��5�$���r?햿Z ��wo�7��a�/��k�(�����#�������D���'�&�'��!�������ͫ�^�p��u�)�&e�<m��lc,��M�Wp���/����S9��o��������9v�`�)�\�}b^���rgn�vϢ[=�\�?<F??F����ݭ�y/��VFdk��6E�.&;CA��S�����WiK�̽�8j.c.�ݞ��4�3��������tzu��n.}i��j��*�tg3����8�u��JVjO�q�'3��^Ok�*oR�Z��������ǫ:WU�:���<+wv��Z�j7F{I�4��u�����&�nX���ѕ�h�غP�������z(*�c�6���V���Tň�~o�2:+�@)O�㒤[B�]���*�rl�]�!nVN�4�T7F�+�iߥ�}��F��T��0q����k�~D�?�N�7��b��9 l ���[����_���d��c�� �����9���oX�������ҏ��0�1E���q���SY�n���B���=�6Q��!������F���^�����0p�z�i3~�i�� �N�s[ܯ�)���Qc��1�p�Lz^0?-Uk�j�b�Oؔ��uu���������q'_N��pǰ�$ߠHpŷs �s�=9 i�Q�REUxQ�g8��ŦK��B���3�4�Ĝ��ۛ�C?r M�v��C퍪"�̊b!o������h+���eu�K6%��/�ڂ����Do�vA��Б��EUVY\_e����0����K�������������,��  n������8��?�����m����̝�'����f�]� ��������^��������a.bЧCI�#:�d��#Y	����@�Y.�A�'�8�#KH�	!� �������7��?|��7���fSklfee��Ej�R�t���9X.˪�N�]����o�ݡ����Iloq���T:��Ue�)�aL���wr;�I�.C���XsW������{-6dQ��uoj��B͞n�
��U���C���P���-�зP�����+D�?��(������b���$�?������p�p,e�^^-�	���QX��ۓsǼ|g�i���k���z�"��K�\�[���M��l���h8�)g� +�̱jm��h����y�����n�[[o�86)�9�5���]��SCp���*�X�Y��-���+�}�k�'��������/����/���W��h�"@�����������xK�����?��V���ʠ��ݡ�����/����G�Gmw�v�6��&����:����\��v���K�a�lE�[%~L�����v0�j�$�t�l�����t��\���s�l#.u�Ӭ�	�;�rR���ԭ��OW������U��׫j��]�;-6���S�M�Y,�b�Z+�q;t�C_�}�9g�z��W�%˔3lq�V��^#�-T�p+VM:��V���e����f���P�ЧV��qu�{�d6�:Ӭ�p�1k��63�ˬ4QTv'��P
�[nQ�։ m�����$�?��S��������J2p������;��X@�w��� �CWR��_4�������+i��������W,���0�����B��x����L���`�� ����	�ϲ��v��/D��'��A� ����C��?���0�T��������_��?�x!
$��{�_x���0�����?���+����N�?�>�x~r�������<�H������� �Á?�������_���> ����C��P�'ܜ���WL������|ߧy��&h°!�HA�"��-�r�!����;q$���O�몝��A��y+	q��6���ё������)�6.��m`��څR��+���IS��д��B�����a�a��S���}����O����a]���y75����H
����2W�q���ާkU�n�����VN���Rc�n߳��m�
Cҿ+f�A��f�P�������4n�g�U/M�]���(���n��V���e���S'�Y>���[��j��O���!���?��/�(b�&���w:���=���B���x��iҡ�?��w�����������Ǎ�������;���ZVF^��r�e4
aK��2bR*�d5�e(�3dfĨL�c��@�� 2
d5^�:�_�?��qz��0:�1,ϰl���w�y�3�K�C�*�I��4.l,{i����'�ɻ��%)�I��"euHW<sH�Z�F���j0�[������:�N�z0q�^��E�ǐY���Kϓf.����Na����ǣ���%���t�����?M���C�)�?M��31�����/�,�OǦ�c�?>�?����9��C�b������O�Y���?�����G��c�?:����b�?�������?z����������������������{����p:��5���Ǣ���������H6v�?>�� tR��?S�@:���PR���^��C������Β�,��Ǐ�t��4�F�kw����������s��3�{����{O���7��;�
�,)&�Z�Y���yך��-��Ya�ӥ�<̸�y�VJBI(�>��Xw�~z�����I�]�Z�Z�*��{O������A��K�7!�*��ȵ�b3(���Ol�����mİ�,��2k��{�(3�Lg1���i�lh���s�#Ԓ�Y ۼ��;K&��l��^��8���K1s�RV\SY�W��j��U��L'a�Q�s�/~�� t������������m��������?�N��S�M����;��fc��������������w$�o�����_�b��׶�N�c��htZ��������S������ѫ����U���-��׭^�|�%��ʾ�[��ͧX��K��O#�~\{��R��[��w�im����}�/-���S;��gB��k��̲��o�vG*dW�{�ތ�ʍ�۩�B��b���<ՎD��De�7cP��jGj�]��z�D�q�$L#7iD"(8��b��
e<�)����<����G)�!��y��?S^
M�0]�;՞]Yp�cP�OR^:7&��εP�*�~�3[��@.�弬�#U��p�2�6Wr�Z���Ҫ��I�#T�<[ ��������_]�VU�G���|UtC_�4�U�̗��3�}N(	Y�iU�Ayv7���Z��u���A_���,�U�~h:�'u�*u�RSd�r3M��~�t�����T?�[�s.WJ������BԒzIo��i{V�^ivޖ�T
�Y�o7�j�!��Jd��B�u[|����$�?j�����B'`�M���l���(��m���y"��_��:%��F
ũ���d��R���fRd*�U 	Y%�p��QU&��iN�E%5���,�������t
�������?�����}eX�,�n$��Z�pm7�p����Ϟ3��8�Wo�t� ���of2Z�Z���B��~/5�J��J���8/�qe�Lo���B����bD�u���꒑�u+�����̓zJ/x��Z�d����V:��?>��xt���3�Eߣ�)����w<:	����8� �G�&�x�����?���G���������������&�ak����twZq$՚�5Ն��o�?�¤�RO�I��k+7}��׮2s���m�����T'[���v��k���@(���N�?ҁ�6�M�'�l��S���V:�����G���U9�:��}��@���W���x���������_q�'�����m�c�I����cR��wz���#�OO?����Y� �2�g7\e��$CZ����M����=�m���[-�@����� ��?��ضg��@��Z���k�x��{ ��bd��n�O�W<�)��=%�CgD4��I�|�*yk�n�Z�^���Z�W��7���s�ڵ��qd��zk:�lͳf}��>l�����	�����"���慠* �t)/ ��'o�0P�e�����=!�d�{Ϲ�����K�L��δ�n��ݪ�G'6��p.�-�ޔ��CM��pex��@�RS,I�2Yv�y>����{U8�E�0�\�bvztw�c��^�a�Iض띕Ȥyӛ��"����L�/��쯦���݈?���'V��|��W�?ͱ�.��)��b�?}�=_9�>�@I��+g� �i�NsA�r�%�O�'�n�n.*�
-^�4hy�Ȁ�%��:�t�D�PƋ�#����h�	M�\���`���m���lɺa�(9|X��w��V}.	 ޗ9�.�x_��<��[% ��g�a]�-�-L�1ǳ���(�!�Ȁt�M; #�jL�A��-� 4�T��*��O�1E����sֲ����i[�"�|���ԇ
o��Qr��-�ƿk����ol���j( ��%+&D����4T�C*�-Bc$�.0,��}g�/��}'�� U���]�e�$Ё��d�ic�a�'l6@5�- ;����DT/�1��xKhxL[�]W	e������������|Á�W��ڏ/�F�,�WF���������#�>��H6��CȐͯa]�=歛���md�8�1�<0�%��XC�V��e��~�F��e|��cߥ�?�Hl��[]E�����w�c���x(/*��B6}���c����6?�F����	�к�߁�9�4W��-�}:�#�Fi�,s�Pʳp��VS�G�9�;��e���Pԅ"�H���\�d��[%Ev^H��8p�h���2���'�P�v �ª1���o,�.B��Q�4�ew>6�d�\���'?�@⹖��=E�)gx:�O�,z���#ھ�]P��>��V�z�ki�3M����L��}�=��xO����%����_����|P}�>*C�����Ǫ�e3�_;*X��f?`#֨5⎱l�|���@E5}iM;��@�����ݐ.]F�2�1�u!.+����
!:bڑQ����x�V^�M�p1����Ɓh�.��Dڍ���U�[�A�����,�a���X��ǩS�s�K�>��H(�[�����n�l,kZ�a�X��#n>�Fas��+N���c;�l�7L-�-����'Y�}���i6��BQ8G�@�C���:�s���!��d;��B�$ފ��m���>7�9"��-1���c�d��k�Y��T2
���{s�L[��ă|]�����o|��8�-�Vb����r��%"��ߥ��^�?w�a��а����?�Kq��?4~K���Z0�b8*��Cq45]��������p�s{4�3YG��x5��	5	�ZdT��3��Ț#l�Zñ-��>�Y6����U�*	=5���Z&�<ؖZ=���x�bOe�O�{
G���
�,u�x*��*K�+G�iM1��B˲��4�SdR�tz��pDi܈�eZa��YZSF�(��Y6e:-ߺS"�0��[��3�L���Od�0�@/�;F�~{Z�ȮƳ���M��ͭ��1��)\�K*++锬(
�fHN�5���J�YY��i692��@FV4|��̠��d!�AJN�u�P@x��e�w����7����Vw%~|�[���om�z,��C�6���I1ʸF>�ħ�����Ʈ�x���[9���� դ_����'U�4�����J�T�s���n_���s�ۥvU��+,!�eݯ^��%���F�|��n�rWk�]��;Wj=�>�b���w�$��)�Uo5ùI{�%u{.{��I9u�����UZ{+z�Dё��X��}���s1�t�N�]��<��`[����9��ԧ=�J����~yߟ����M��zK�B^(Ր�+I�'���|�&�s�9#��IB����W��j�F�T�\����L&�8Β\�N��m�p��3|~�$�;�ͻѶzI��n��XF���X��K�ۚ���[�*j��F�n����BwTG����1J���n�3��~P��A�r�l��w��o���ߖ�����s�w���X�	�6��6���5�2�Ͱ猪�6�(N�X�r9�j$�.|A���ABNa^R�!�ܕ�?���p���r���O��c쇕�V�]�shi�-�r���[���t쟭���7O�Ɉc�{�=p�n��
*��Pw&�&�x�Ç�3��O���?�ƾ����hv`�Û	w�e�����(��M�$�R��0�����CЧ�H*��Tdw�_ې�xI�#�q= �v~sǰ< ������N.�=��T�*�:6�/߁�����ad�b�w̹��J�V}��˛`Qn�Y%l=�}�T�Н�ɳ� �/޶�ݖ(�/�����3𗿀y��_�m{�#VH0C޹p}���uw�z����ڇ����v�`F���9��<{�)ӣʼ)3�"��g�"Z�U�$>9�+9���C}�4g����ъ�6Ѱ���9�fv�-ָɿnN>*����F��/X_;3|��s`��+����l��t��i. �	e���K�[������`?���������4�Пah��t�eb�?� �f"��g�{��C%�@6�������e�XqN��W�;c�����7�+������#9�t���4��=���kU��
���Bul#����HG��
� ��{d�m�^� [�	�%���?>C�-��9i���_���q̣���`
.�	���˗��S���,Pߢ��?ۻ�޴� ���b�EJU�c�J��ڗ�RԾDy0�P7��H�wfw}�M�Gz��B�wgg���~	�g(��`�U���Ӑ{8��'�m���e�E�}0%KrCͲ��:�b�ӶN '�V�`�Ȗ����ܹ�D$���ݍ�ޗQ$2"��w��}��߄eB�O�W"���ƙ��L�axC�`f�C�q�	��T=_��^�O�t9��%M������Z����� ���M}q�1���4��7.S��A���;N�S�S�F�24g�ID;�V��f�UE6^n-��(2��/5 �F��CvY�_��lJx�gj�Gf�6��׊�rI;�t�}I�M^.�u4�%�q,Kl~fB��̡�Փ]�}9��_v*��m��?��^w0����X��뇣�xA�=sB��t��o�k��������~�w�N�*_T׻�������r���&�̠5�̜>W;�}�K���7~w6��P���W�Bh�rTD���PG���M�A�kIqt��¼o�Z���W�x��,��&��f�211p�Q��<���xU��D��gf�p(��grd��_�q�_*]c�� ���ά����=C-����d��>��߯�
��|�>����
��-�����C�>z?����}�'d����%�YCUqE Hp��IĈ��~��M�fk5��&�J.�aR�q�~��Uv���bj��#��XS�Ӧ���?ч���I�����ief�}�t��t�� [:J@�G�f��`0��`0��`0��7��T 0 