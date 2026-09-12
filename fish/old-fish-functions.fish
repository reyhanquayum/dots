
# Start/create persistent GIOS container
function gios-start
    docker run -d --name gios-dev \
        -v ~/Documents/OMSCS/gios/projects/:/workspace \
        -w /workspace \
        gios-custom \
        sleep infinity
end

# Auto-start containers if they exist but aren't running
function gios
    if not docker ps -q -f name=gios-dev > /dev/null
        if docker ps -a -q -f name=gios-dev > /dev/null
            docker start gios-dev
        else
            echo "Run gios-start first!"
            return 1
        end
    end
    docker exec -it gios-dev bash -c "tmux new -A -s gios"
end

function gios-stop
  docker stop gios-dev
  docker rm gios-dev
end

# Start/create persistent HPCA container
function hpca-start
    docker run -d --name hpca-dev \
        -v ~/Documents/OMSCS/hpca/projects/:/home/cs6290 \
        -w /home/cs6290 \
        jsachs123/cs6290 \
        sleep infinity
end

# Same for HPCA
function hpca
    if not docker ps -q -f name=hpca-dev > /dev/null
        if docker ps -a -q -f name=hpca-dev > /dev/null
            docker start hpca-dev
        else
            echo "Run hpca-start first!"
            return 1
        end
    end
    docker exec -it hpca-dev bash
end

# Stop HPCA container when done
function hpca-stop
    docker stop hpca-dev
    docker rm hpca-dev
end
